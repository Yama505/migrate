<#
migrate_vm_02.ps1
PowerCLI
https://www.powershellgallery.com/packages/VMware.PowerCLI/11.5.0.14912921
#>

#実行ポリシー設定
Set-ExecutionPolicy RemoteSigned

###動作パラメーター定義
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
#エクスポート先のパス
$vm_export_path ='C:\export_vms_20200217'
#エクスポートする仮想マシン名の配列
$vm_target = 'ws2012_01','ws2012_02'
#$vm_target = 'ws2012_03'

##
##3
$log_filename = 'migrate_vm_log.txt'
###

###
###Log書き込み
function WriteLog($line){
    $logtime = Get-Date
    $msg = $logtime.ToString() + ' : ' + $line
    Write-Output $msg | Add-Content $log_filename -Encoding Default
}
###

###開始
WriteLog('スクリプトの開始')

#エクスポート先フォルダ確認と作成
if((Test-Path $vm_export_path) -eq $false)
{
    New-Item -Path $vm_export_path -ItemType Directory | Out-Null
}


#PowerCLI設定11.5.0
$set_powercli = Set-PowerCLIConfiguration -Scope AllUsers -InvalidCertificateAction Ignore -ParticipateInCeip $false -Confirm:$false -WebOperationTimeoutSeconds 144000

foreach($i_vm in $vm_target)
{
    #旧vCenter接続
    WriteLog('旧vCenter接続')
    Connect-VIServer -Server $old_vcenter -Protocol https -User $old_admin -Password $old_admin_pass | Out-Null

    #VMオブジェクト取得
    $old_vms = Get-VM -Server $old_vcenter
    foreach($old_vm in $old_vms)
    {
        #ターゲットの仮想マシン名が旧vCenterにヒットすれば
        if($old_vm.Name -eq $i_vm)
        {
            #仮想マシンエクスポート
            $msg = $old_vm.Name + 'のエクスポート開始'
            WriteLog($msg)
            Export-VApp -Destination $vm_export_path -VM $old_vm -Format Ovf | Out-Null
            $msg = $old_vm.Name + 'のエクスポート終了'
            WriteLog($msg)
    
            #旧vCenter切断
            WriteLog('旧vCenter切断')
            Disconnect-VIServer -Server $old_vcenter -Force -Confirm:$false
    
            #新vCenterへ接続
            WriteLog('新vCenter接続')
            Connect-VIServer -Server $new_vcenter -Protocol https -User $new_admin -Password $new_admin_pass | Out-Null
    
            #仮想マシンインポート
            $myDatastore = Get-Datastore -Name $new_ds -Server $new_vcenter
            $vmHost = Get-VMHost -Name $new_vmhost
            $ovf_path = $vm_export_path + '\' + $old_vm.Name + '\' + $old_vm.Name + '.ovf'
    
            $msg = $i_vm + 'のインポート開始'
            WriteLog($msg)
            $vmHost | Import-vApp -Source $ovf_path -Datastore $myDatastore -Force | Out-Null
            $msg = $i_vm + 'のインポート終了'
            WriteLog($msg)
    
            #新vCenter切断
            WriteLog('新vCenter切断')
            Disconnect-VIServer -Server $new_vcenter -Force -Confirm:$false
        }
    }
}

WriteLog('スクリプトの終了')
