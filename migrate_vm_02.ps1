<#
migrate_vm_02.ps1
PowerCLI
https://www.powershellgallery.com/packages/VMware.PowerCLI/11.5.0.14912921
#>

#���s�|���V�[�ݒ�
Set-ExecutionPolicy RemoteSigned

###����p�����[�^�[��`
#1
$old_vcenter = '192.168.20.97'
$old_admin = 'administrator'
$old_admin_pass = '!!!Password123'

$new_vcenter = '192.168.20.96'
$new_admin = 'administrator@vsphere.local'
$new_admin_pass = '!!!Password123'
$new_ds = 'datastore2'
$new_vmhost = '192.168.20.91'

##
##2
#�G�N�X�|�[�g��̃p�X
$vm_export_path ='C:\export_vms_20200217'
#�G�N�X�|�[�g���鉼�z�}�V�����̔z��
$vm_target = 'ws2012_01','ws2012_02'
#$vm_target = 'ws2012_03'

##
##3
$log_filename = 'migrate_vm_log.txt'
###

###
###Log��������
function WriteLog($line){
    $logtime = Get-Date
    $msg = $logtime.ToString() + ' : ' + $line
    Write-Output $msg | Add-Content $log_filename -Encoding Default
}
###

###�J�n
WriteLog('�X�N���v�g�̊J�n')

#�G�N�X�|�[�g��t�H���_�m�F�ƍ쐬
if((Test-Path $vm_export_path) -eq $false)
{
    New-Item -Path $vm_export_path -ItemType Directory | Out-Null
}


#PowerCLI�ݒ�11.5.0
$set_powercli = Set-PowerCLIConfiguration -Scope AllUsers -InvalidCertificateAction Ignore -ParticipateInCeip $false -Confirm:$false -WebOperationTimeoutSeconds 144000

foreach($i_vm in $vm_target)
{
    #��vCenter�ڑ�
    WriteLog('��vCenter�ڑ�')
    Connect-VIServer -Server $old_vcenter -Protocol https -User $old_admin -Password $old_admin_pass | Out-Null

    #VM�I�u�W�F�N�g�擾
    $old_vms = Get-VM -Server $old_vcenter
    foreach($old_vm in $old_vms)
    {
        #�^�[�Q�b�g�̉��z�}�V��������vCenter�Ƀq�b�g�����
        if($old_vm.Name -eq $i_vm)
        {
            #���z�}�V���G�N�X�|�[�g
            $msg = $old_vm.Name + '�̃G�N�X�|�[�g�J�n'
            WriteLog($msg)
            Export-VApp -Destination $vm_export_path -VM $old_vm -Format Ovf | Out-Null
            $msg = $old_vm.Name + '�̃G�N�X�|�[�g�I��'
            WriteLog($msg)
    
            #��vCenter�ؒf
            WriteLog('��vCenter�ؒf')
            Disconnect-VIServer -Server $old_vcenter -Force -Confirm:$false
    
            #�VvCenter�֐ڑ�
            WriteLog('�VvCenter�ڑ�')
            Connect-VIServer -Server $new_vcenter -Protocol https -User $new_admin -Password $new_admin_pass | Out-Null
    
            #���z�}�V���C���|�[�g
            $myDatastore = Get-Datastore -Name $new_ds -Server $new_vcenter
            $vmHost = Get-VMHost -Name $new_vmhost
            $ovf_path = $vm_export_path + '\' + $old_vm.Name + '\' + $old_vm.Name + '.ovf'
    
            $msg = $i_vm + '�̃C���|�[�g�J�n'
            WriteLog($msg)
            $vmHost | Import-vApp -Source $ovf_path -Datastore $myDatastore -Force | Out-Null
            $msg = $i_vm + '�̃C���|�[�g�I��'
            WriteLog($msg)
    
            #�VvCenter�ؒf
            WriteLog('�VvCenter�ؒf')
            Disconnect-VIServer -Server $new_vcenter -Force -Confirm:$false
        }
    }
}

WriteLog('�X�N���v�g�̏I��')
