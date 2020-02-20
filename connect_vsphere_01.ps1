<#
connect_vsphere_01.ps1
202002191730
PowerCLI
https://www.powershellgallery.com/packages/VMware.PowerCLI/11.5.0.14912921
#>

#実行ポリシー設定
Set-ExecutionPolicy RemoteSigned

#実行時刻取得
$start_time = Get-Date -Format "yyyyMMddHHmmss"

###動作パラメーター定義
#移行先vCenter接続情報
$destination_vcenter = '192.168.20.96'
$destination_admin = 'administrator@vsphere.local'
$destination_admin_pass = '!!!Password123'
$log_name = 'vm_info_'
$log_filename = $log_name + $start_time + '.txt'
##

###関数
###Log書き込み
function WriteLog($line){
    $logtime = Get-Date
    $msg = $logtime.ToString() + ' : ' + $line
    Write-Output $msg | Add-Content $log_filename -Encoding Default
}

###メイン

#PowerCLI設定（11.5.0）
Set-PowerCLIConfiguration -Scope AllUsers -InvalidCertificateAction Ignore -ParticipateInCeip $false -Confirm:$false -WebOperationTimeoutSeconds 144000 | Out-Null
    
#vCenterへ接続
Connect-VIServer -Server $destination_vcenter -Protocol https -User $destination_admin -Password $destination_admin_pass | Out-Null

#ステータス確認
$vm_dc = Get-Datacenter
WriteLog($vm_dc | Out-String)
$vm_cs = Get-Cluster
WriteLog($vm_cs | Out-String)
$vm_hs = Get-VMHost
WriteLog($vm_hs | Out-String)
$vm_ds = Get-Datastore
WriteLog($vm_ds | Out-String)
$vms = get-vm | Select-Object Name,VMHost,PowerState
WriteLog($vms | Out-String)

Disconnect-VIServer -Server $destination_vcenter -Force -Confirm:$false

###

