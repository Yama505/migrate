<# check_01.ps1 #>

$source_vcenter = '192.168.20.97'
$destination_vcenter = '192.168.20.96'
$destination_ds = 'datastore2'
$destination_vmhost = '192.168.20.91'
$vm_target = 'ws2012_01','ws2012_03','ws2012_02'


Write-Host '�p�����[�^�m�F'
Read-Host "�L�[���͑҂�"
Write-Host '�ڍs��vCenter�T�[�o�[�F' $source_vcenter
Read-Host "�L�[���͑҂�"
Write-Host '�ڍs��vCenter�T�[�o�[�F' $destination_vcenter
Read-Host "�L�[���͑҂�"
Write-Host '�ڍs��f�[�^�X�g�A�F' $destination_ds
Read-Host "�L�[���͑҂�"
Write-Host '�ڍs�扼�z�z�X�g�F'�@$destination_vmhost
Read-Host "�L�[���͑҂�"
Write-Host '�ڍs�Ώۉ��z�}�V���F' $vm_target
Read-Host "�L�[���͑҂�"
