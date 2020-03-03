<#
migrate_vm_02.ps1
20200303135900
1.PSCredential�𗘗p���ăp�X���[�h���L�ڂ��Ȃ��悤�ɕύX����
2.�p�����[�^���m�F�ł���悤�ɂ���

PowerCLI
https://www.powershellgallery.com/packages/VMware.PowerCLI/11.5.0.14912921
#>

#���s�|���V�[�ݒ�
Set-ExecutionPolicy RemoteSigned

###����p�����[�^�[��`
##1�������
#�X�N���v�g�J�n�����̎擾
$start_time = Get-Date -Format "yyyyMMddHHmmss"

##1���O�t�@�C����
$log_name = '_migrate_vm_log.txt'
$log_filename = $start_time + $log_name
##
##2vCenter���
#�ڍs��vCenter�ڑ����
$source_vcenter = '192.168.20.97'
#$source_admin = 'administrator'
#$source_admin_pass = '!!!Password123'
#�ڍs��vCenter�ڑ����
$destination_vcenter = '192.168.20.96'
#$destination_admin = 'administrator@vsphere.local'
#$destination_admin_pass = '!!!Password123'
$destination_ds = 'datastore2'
$destination_vmhost = '192.168.20.91'
#�C���|�[�g�O���z�}�V�����d���`�F�b�N�ϐ�
$dep_flag = 0 #����t���O
$destination_dep_vm = @() #�d�����z�}�V�����X�g
##
##3
#�G�N�X�|�[�g��̃p�X
$vm_export_path ='C:\export_vms_' + $start_time
#�G�N�X�|�[�g���鉼�z�}�V�����̔z��
$vm_target = 'ws2012_01','ws2012_03','ws2012_02'
#$vm_target = 'ws2012_03'
##
###

###�֐�
###Log��������
function WriteLog($line){
    $logtime = Get-Date
    $msg = $logtime.ToString() + ' : ' + $line
    Write-Output $msg | Add-Content $log_filename -Encoding Default
}
###

###���C��
WriteLog('�X�N���v�g�̊J�n')

#�p�����[�^�[�ڎ��m�F
#�m�F�p�����[�^�̕\��
Write-Host '[�p�����[�^���m�F]'
Write-Host "�ڍs��vCenter�T�[�o�[`t�F" $source_vcenter
Write-Host "�ڍs��vCenter�T�[�o�[`t�F" $destination_vcenter
Write-Host "�ڍs��f�[�^�X�g�A`t�F" $destination_ds
Write-Host "�ڍs�扼�z�z�X�g`t�F"�@$destination_vmhost
Write-Host "�ڍs�Ώۉ��z�}�V��`t�F" $vm_target
Write-Host "�G�N�X�|�[�g�t�H���_`t:" $vm_export_path

#���f�҂�
$key = Read-Host "���Ȃ��̂Ōp���iY�j,��肠��̂Œ��f�iN�j,�f�t�H���g�iN�j"

#���f����
$key
switch ($key) {
    'Y' { Write-Host '�X�N���v�g���p�����܂�'  }
    Default { Write-Host '�X�N���v�g�𒆒f���܂�' ; exit }
}


#�G�N�X�|�[�g��f�B���N�g���m�F�ƍ쐬
if((Test-Path $vm_export_path) -eq $true)
{
    $msg = '�G�N�X�|�[�g��t�H���_�u ' + $vm_export_path + ' �v�����ɑ��݂���̂ŃX�N���v�g���~���܂�'
    WriteLog($msg)
    exit
}
else {
    #�G�N�X�|�[�g��f�B���N�g���̍쐬
    New-Item -Path $vm_export_path -ItemType Directory | Out-Null
}

#PowerCLI�ݒ�i11.5.0�j
Set-PowerCLIConfiguration -Scope AllUsers -InvalidCertificateAction Ignore -ParticipateInCeip $false -Confirm:$false -WebOperationTimeoutSeconds 144000  | Out-Null

#���O�ڑ��e�X�g
do{
    $source_cred = Get-Credential  -Message '�y�ڍs����vCenter�ڑ��A�J�E���g���z'
    $s_v = Connect-VIServer -Server $source_vcenter -Protocol https -Credential $source_cred -ErrorAction SilentlyContinue
}while($null -eq $s_v)
Write-Host $s_v.Name  $s_v.SessionId
Get-vm -Server $source_vcenter
Disconnect-VIServer -Server $source_vcenter -Force -Confirm:$false
Write-Host "`r`n"

do {
    $destination_cred = Get-Credential -Message '�y�ڍs���vCenter�ڑ��A�J�E���g���z'
    $d_v = Connect-VIServer -Server $destination_vcenter -Protocol https -Credential $destination_cred -ErrorAction SilentlyContinue
}while($null -eq $d_v)
Write-Host $d_v.Name  $d_v.SessionId
Get-Datastore -Name $destination_ds | Select-Object Name,State,CapacityGB,FreeSpaceGB
Get-VMHost -Name $destination_vmhost | Select-Object Name,PowerState
Disconnect-VIServer -Server $destination_vcenter -Force -Confirm:$false

#�ŏI�m�F
$key = $null
$key = Read-Host "�{���ɃX�N���v�g�����s���܂����H`r`n�p���iY�j,��肠��̂Œ��f�iN�j,�f�t�H���g�iN�j"

#�ŏI���f����
$key
switch ($key) {
    'Y' { Write-Host "�X�N���v�g���p�����܂�`r`n"  }
    Default { Write-Host "�X�N���v�g�𒆒f���܂�`r`n" ; exit }
}

#�ڍs�Ώە�����
foreach($i_vm in $vm_target)
{
    #�G�N�X�|�[�g���s�t���O
    $export_f = 0

    #�ڍs��vCenter�ڑ�
    WriteLog('�ڍs��vCenter�ڑ�')
    Connect-VIServer -Server $source_vcenter -Protocol https -Credential $source_cred | Out-Null

    #VM�I�u�W�F�N�g�擾
    $source_vmlist = Get-VM -Server $source_vcenter
    foreach($source_vm in $source_vmlist)
    {
        #�^�[�Q�b�g�̉��z�}�V�������ڍs���ɂ����
        if($source_vm.Name -eq $i_vm)
        {
            #�d���X�e�[�^�X�m�F
            #�X�e�[�^�X��poweroff��������OK
            if($source_vm.PowerState -ne 'PoweredOff')
            {
                WriteLog($source_vm.Name + '�͓d�����I�t�ł͂���܂���')
                $export_f = 1
            }
            else {
                WriteLog($source_vm.Name + '�͓d�����I�t�ł�')
            }

            #�X�i�b�v�V���b�g�m�F
            #�X�i�b�v�V���b�g���Ȃ����OK
            if((Get-Snapshot -vm $source_vm | Measure-Object).Count -eq 0)
            {
                WriteLog($source_vm.Name + '�̓X�i�b�v�V���b�g�͂���܂���')
            }
            else {
                WriteLog($source_vm.Name + '�̓X�i�b�v�V���b�g������܂�')
                $export_f = 1
            }

            #CD�h���C�u��Ԋm�F
            #���f�B�A���Ȃ����OK
            $vmcd = $null
            $vmcd = Get-CDDrive -VM $source_vm | Select-Object Name,IsoPath,HostDevice,RemoteDevice | Sort-Object Name
            #CD�L���t���O������
            $cd_f = 0
            foreach($cd in $vmcd)
            {
                #CD�L������
                if(-Not([string]::IsNullOrEmpty($cd.IsoPath + $cd.HostDevice + $cd.RemoteDevice)))
                {
                    #CD�L���t���O�ݒ�
                    $cd_f = 1
                }
            }
            #
            #CD�L��
            if($cd_f -eq 1)
            {
                WriteLog($source_vm.Name + '�̓��f�B�A������܂�')
                $export_f = 1
            }
            #CD�Ȃ�
            else {
                WriteLog($source_vm.Name + '�̓��f�B�A�͂���܂���')
            }

            #�G�N�X�|�[�g�`�F�b�N���ʂ�����
            if($export_f -eq 0)
            {
                #���z�}�V���G�N�X�|�[�g
                $msg = $source_vm.Name + '�̃G�N�X�|�[�g�J�n'
                WriteLog($msg)
                Export-VApp -Destination $vm_export_path -VM $source_vm -Format Ovf | Out-Null
                $msg = $source_vm.Name + '�̃G�N�X�|�[�g�I��'
                WriteLog($msg)

                #�ڍs��vCenter�ؒf
                WriteLog('�ڍs��vCenter�ؒf')
                Disconnect-VIServer -Server $source_vcenter -Force -Confirm:$false
        
                #�ڍs��vCenter�֐ڑ�
                WriteLog('�ڍs��vCenter�ڑ�')
                Connect-VIServer -Server $destination_vcenter -Protocol https -Credential $destination_cred | Out-Null

                #�ڍs�扼�z�}�V���d���`�F�b�N
                $destination_vmlist = Get-vm -Server $destination_vcenter
                foreach($destination_vm in $destination_vmlist)
                {
                    if($source_vm.Name -eq $destination_vm.Name)
                    {
                        $dep_flag = 1
                        $destination_dep_vm += $source_vm.Name
                    }
                }

                #�ڍs��ɏd�����Ȃ���΃C���|�[�g
                if($dep_flag -eq 0)
                {
                    #���z�}�V���C���|�[�g
                    $myDatastore = Get-Datastore -Name $destination_ds -Server $destination_vcenter
                    $vmHost = Get-VMHost -Name $destination_vmhost
                    $ovf_path = $vm_export_path + '\' + $source_vm.Name + '\' + $source_vm.Name + '.ovf'
            
                    $msg = $i_vm + '�̃C���|�[�g�J�n'
                    WriteLog($msg)
                    $vmHost | Import-vApp -Source $ovf_path -Datastore $myDatastore -Force | Out-Null
                    $msg = $i_vm + '�̃C���|�[�g�I��'
                    WriteLog($msg)
                }
                else {
                    WriteLog($source_vm.Name + '�͈ڍs��ɓ��ꉼ�z�}�V����������܂�')
                }
                #�ڍs��vCenter�ؒf
                WriteLog('�ڍs��vCenter�ؒf')
                Disconnect-VIServer -Server $destination_vcenter -Force -Confirm:$false
                #�C���|�[�g�O���z�}�V���d���t���O������
                $dep_flag = 0
            }
            else {
                WriteLog($source_vm.Name + '�̓G�N�X�|�[�g�����Ɏ��̉��z�}�V���փX�L�b�v���܂�')
            }
        }
    }
}

#�C���|�[�g���Ȃ��������X�g
if([string]::IsNullOrEmpty($destination_dep_vm))
{
    WriteLog('�G�N�X�|�[�g�������������z�}�V���ŃC���|�[�g���X�L�b�v�������z�}�V���͂���܂���')
}
else {
    $msg = '�G�N�X�|�[�g������A�ڍs�扼�z�}�V�����d���ɂ��C���|�[�g���Ȃ��������z�}�V�� : ' + $destination_dep_vm
    WriteLog($msg)      
}
#

WriteLog('�X�N���v�g�̏I��')
###
