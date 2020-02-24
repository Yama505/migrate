<#
info_vm_01.ps1
PowerCLI
https://www.powershellgallery.com/packages/VMware.PowerCLI/11.5.0.14912921
#>

#実行ポリシー設定
Set-ExecutionPolicy RemoteSigned
#スクリプト開始時刻の取得
$start_time = Get-Date -Format "yyyyMMddHHmmss"

##1ログファイル名
$log_name = '_migrate_vm_info.txt'
$log_filename = $start_time + $log_name

###動作パラメーター定義
#1
$source_vcenter = '192.168.20.97'
$source_admin = 'administrator'
$source_admin_pass = '!!!Password123'

$destination_vcenter = '192.168.20.96'
$destination_admin = 'administrator@vsphere.local'
$destination_admin_pass = '!!!Password123'

###開始

#PowerCLI設定11.5.0
Set-PowerCLIConfiguration -Scope AllUsers -InvalidCertificateAction Ignore -ParticipateInCeip $false -Confirm:$false -WebOperationTimeoutSeconds 144000 | Out-Null


#移行元vCenter接続
Connect-VIServer -Server $source_vcenter -Protocol https -User $source_admin -Password $source_admin_pass | Out-Null

#VMオブジェクト取得
$res = Get-VM -Server $source_vcenter | Select-Object *
$res | select-Object * | Out-string | Add-Content $log_filename -Encoding Default

#移行元vCenter切断
Disconnect-VIServer -Server $source_vcenter -Force -Confirm:$false

#移行先vCenter接続
Connect-VIServer -Server $destination_vcenter -Protocol https -User $destination_admin -Password $destination_admin_pass | Out-Null

#VMオブジェクト取得
$res = Get-Datacenter -Server $destination_vcenter
$res | select-Object * | Out-string | Add-Content $log_filename -Encoding Default
$res = Get-Cluster -Server $destination_vcenter
$res | select-Object * | Out-string | Add-Content $log_filename -Encoding Default
$res = Get-Datastore -Server $destination_vcenter
$res | select-Object * | Out-string | Add-Content $log_filename -Encoding Default
$res = Get-VM -Server $destination_vcenter | Select-Object *
$res | select-Object * | Out-string | Add-Content $log_filename -Encoding Default

#移行元vCenter切断
Disconnect-VIServer -Server $destination_vcenter -Force -Confirm:$false




