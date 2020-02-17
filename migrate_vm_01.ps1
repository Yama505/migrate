<#
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

# 
##2
#エクスポート先のパス
$vm_export_path ='C:\export_vms'
#エクスポートする仮想マシン名の配列
$vm_target = 'ws2012_01','ws2012_02'
#
###

#PowerCLI設定11.5.0
$set_powercli = Set-PowerCLIConfiguration -Scope AllUsers -InvalidCertificateAction Ignore -ParticipateInCeip $false -Confirm:$false -WebOperationTimeoutSeconds 144000


foreach($i_vm in $vm_target)
{
    #旧vCenter接続
    Connect-VIServer -Server $old_vcenter -Protocol https -User $old_admin -Password $old_admin_pass

    #VMオブジェクト取得
    $vm = Get-VM -Name $i_vm -Server $old_vcenter

    #仮想マシンエクスポート
    Export-VApp -Destination $vm_target -VM $vm -Format Ovf

    #旧vCenter切断
    Disconnect-VIServer -Server $old_vcenter -Force -Confirm:$false

    #新vCenterへ接続
    Connect-VIServer -Server $new_vcenter -Protocol https -User $new_admin -Password $new_admin_pass

    #仮想マシンインポート
    $myDatastore = Get-Datastore -Name $new_ds -Server $new_vcenter
    $vmHost = Get-VMHost -Name $new_vmhost
    $vmHost | Import-vApp -Source "C:\export_vms\ws2012_02\ws2012_02.ovf" -Datastore $myDatastore -Force

    #新vCenter切断
    Disconnect-VIServer -Server $new_vcenter -Force -Confirm:$false
}

