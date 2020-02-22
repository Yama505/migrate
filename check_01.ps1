<# check_01.ps1 #>

$source_vcenter = '192.168.20.97'
$destination_vcenter = '192.168.20.96'
$destination_ds = 'datastore2'
$destination_vmhost = '192.168.20.91'
$vm_target = 'ws2012_01','ws2012_03','ws2012_02'


Write-Host 'パラメータ確認'
Read-Host "キー入力待ち"
Write-Host '移行元vCenterサーバー：' $source_vcenter
Read-Host "キー入力待ち"
Write-Host '移行先vCenterサーバー：' $destination_vcenter
Read-Host "キー入力待ち"
Write-Host '移行先データストア：' $destination_ds
Read-Host "キー入力待ち"
Write-Host '移行先仮想ホスト：'　$destination_vmhost
Read-Host "キー入力待ち"
Write-Host '移行対象仮想マシン：' $vm_target
Read-Host "キー入力待ち"
