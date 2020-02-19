<#
migrate_vm_02.ps1
202002191730
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
$source_admin = 'administrator'
$source_admin_pass = '!!!Password123'
#�ڍs��vCenter�ڑ����
$destination_vcenter = '192.168.20.96'
$destination_admin = 'administrator@vsphere.local'
$destination_admin_pass = '!!!Password123'
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
#$vm_target = 'ws2012_02'
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

foreach($i_vm in $vm_target)
{
    #��vCenter�ڑ�
    WriteLog('�ڍs��vCenter�ڑ�')
    Connect-VIServer -Server $source_vcenter -Protocol https -User $source_admin -Password $source_admin_pass | Out-Null

    #VM�I�u�W�F�N�g�擾
    $source_vmlist = Get-VM -Server $source_vcenter
    foreach($source_vm in $source_vmlist)
    {
        #�^�[�Q�b�g�̉��z�}�V�������ڍs���ɂ����
        if($source_vm.Name -eq $i_vm)
        {
            #�d���X�e�[�^�X�m�F
            $source_vm.PowerState

            #�X�i�b�v�V���b�g�m�F
            Get-Snapshot -vm $source_vm.Name

            #CD�h���C�u��Ԋm�F
            Get-CDDrive -vm $source_vm.Name

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
            Connect-VIServer -Server $destination_vcenter -Protocol https -User $destination_admin -Password $destination_admin_pass | Out-Null

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
            #�VvCenter�ؒf
            WriteLog('�ڍs��vCenter�ؒf')
            Disconnect-VIServer -Server $destination_vcenter -Force -Confirm:$false
        }
    }
}

#�C���|�[�g���Ȃ��������X�g
$msg = '�ڍs�扼�z�}�V�����d���ɂ��C���|�[�g���Ȃ��������z�}�V�� : ' + $destination_dep_vm
WriteLog($msg)
#

WriteLog('�X�N���v�g�̏I��')
###

