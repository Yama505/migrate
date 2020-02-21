<#
migrate_vm_03.ps1
�񓯊����s�e�X�g
PowerCLI
https://www.powershellgallery.com/packages/VMware.PowerCLI/11.5.0.14912921
#>

#���s�|���V�[�ݒ�
Set-ExecutionPolicy RemoteSigned

#�ڍs��vCenter�ڑ����
$source_vcenter = '192.168.20.97'
$source_admin = 'administrator'
$source_admin_pass = '!!!Password123'

#�X�N���v�g�J�n�����̎擾
$start_time = Get-Date -Format "yyyyMMddHHmmss"
$vm_export_path ='C:\export_vms'

#�񓯊����s�R�}���h
$PSCmds = @(
    "Export-VApp -Destination 'C:\export_vms' -VM 'ws2012_01' -Format Ovf",
    "Export-VApp -Destination 'C:\export_vms' -VM 'ws2012_02' -Format Ovf",
    "Export-VApp -Destination 'C:\export_vms' -VM 'ws2012_03' -Format Ovf"
)


#�񓯊������֐�
function AsyncPowershell($Cmds) 
{
    try {
        #�񓯊����s�R�}���h�����v�Z
        $MaxRunspace = $Cmds.Length
        #
        $RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, $MaxRunspace)        
	    $RunspacePool.Open()
	    
        $aryPowerShell  = New-Object System.Collections.ArrayList
        $aryIAsyncResult  = New-Object System.Collections.ArrayList
        for ( $i = 0; $i -lt $MaxRunspace; $i++ )
        {
            $Cmd = $Cmds[$i]
            $PowerShell = [PowerShell]::Create()
	        $PowerShell.RunspacePool = $RunspacePool
            $PowerShell.AddScript($Cmd)
            $PowerShell.AddCommand("Out-String")
            $IAsyncResult = $PowerShell.BeginInvoke()
                       
            $aryPowerShell.Add($PowerShell)
            $aryIAsyncResult.Add($IAsyncResult)
        }

        while ( $aryPowerShell.Count -gt 0 )
        {
            for ( $i = 0; $i -lt $aryPowerShell.Count; $i++ )
            {
                $PowerShell = $aryPowerShell[$i]
                $IAsyncResult = $aryIAsyncResult[$i]    

                if($PowerShell -ne $null)
                {
                    if($IAsyncResult.IsCompleted)
                    {
                        $Result = $PowerShell.EndInvoke($IAsyncResult)
                        Write-host $Result
                        $PowerShell.Dispose()
                        $aryPowerShell.RemoveAt($i)
                        $aryIAsyncResult.RemoveAt($i)
                        {break outer}
                    }
                }           
            }
            Start-Sleep -Milliseconds 100
        }
    } catch [Exception] {
        Write-Host $_.Exception.Message; 
    } finally {
        $RunspacePool.Close()
    }
}

###���C�����[�`��
#�G�N�X�|�[�g��f�B���N�g���m�F�ƍ쐬
New-Item -Path $vm_export_path -ItemType Directory

#PowerCLI�ݒ�i11.5.0�j
Set-PowerCLIConfiguration -Scope AllUsers -InvalidCertificateAction Ignore -ParticipateInCeip $false -Confirm:$false -WebOperationTimeoutSeconds 144000
Connect-VIServer -Server $source_vcenter -Protocol https -User $source_admin -Password $source_admin_pass
$res = AsyncPowershell $PSCmds
Disconnect-VIServer -Server $source_vcenter -Force -Confirm:$false

