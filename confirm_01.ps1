<# confirm_01.ps1 
メインルーチン実行前のパラメータ確認スクリプト
#>

#パラメータ
$source_vcenter = '192.168.20.97'
$destination_vcenter = '192.168.20.96'
$destination_ds = 'datastore2'
$destination_vmhost = '192.168.20.91'
$vm_target = 'ws2012_01','ws2012_03','ws2012_02'

#確認パラメータの表示
Write-Host '[パラメータを確認]'
Write-Host "移行元vCenterサーバー`t：" $source_vcenter
Write-Host "移行先vCenterサーバー`t：" $destination_vcenter
Write-Host "移行先データストア`t：" $destination_ds
Write-Host "移行先仮想ホスト`t："　$destination_vmhost
Write-Host "移行対象仮想マシン`t：" $vm_target

#判断待ち
$key = Read-Host "問題ないので継続（Y）,問題あるので中断（N）,デフォルト（N）"

#判断処理
$key
switch ($key) {
    'Y' { Write-Host 'スクリプトを継続します'  }
    Default { Write-Host 'スクリプトを中断します' ; exit }
}
