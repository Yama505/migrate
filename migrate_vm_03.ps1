<#
migrate_vm_02.ps1
202002191730
PowerCLI
https://www.powershellgallery.com/packages/VMware.PowerCLI/11.5.0.14912921
#>

#実行ポリシー設定
Set-ExecutionPolicy RemoteSigned

###動作パラメーター定義
##1初期情報
#スクリプト開始時刻の取得
$start_time = Get-Date -Format "yyyyMMddHHmmss"

##1ログファイル名
$log_name = '_migrate_vm_log.txt'
$log_filename = $start_time + $log_name
##
##2vCenter情報
#移行元vCenter接続情報
$source_vcenter = '192.168.20.97'
$source_admin = 'administrator'
$source_admin_pass = '!!!Password123'
#移行先vCenter接続情報
$destination_vcenter = '192.168.20.96'
$destination_admin = 'administrator@vsphere.local'
$destination_admin_pass = '!!!Password123'
$destination_ds = 'datastore2'
$destination_vmhost = '192.168.20.91'
#インポート前仮想マシン名重複チェック変数
$dep_flag = 0 #判定フラグ
$destination_dep_vm = @() #重複仮想マシンリスト
##
##3
#エクスポート先のパス
$vm_export_path ='C:\export_vms_' + $start_time
#エクスポートする仮想マシン名の配列
$vm_target = 'ws2012_01','ws2012_03','ws2012_02'
#$vm_target = 'ws2012_02'
##
###

###関数
###Log書き込み
function WriteLog($line){
    $logtime = Get-Date
    $msg = $logtime.ToString() + ' : ' + $line
    Write-Output $msg | Add-Content $log_filename -Encoding Default
}
###

###メイン
WriteLog('スクリプトの開始')

#エクスポート先ディレクトリ確認と作成
if((Test-Path $vm_export_path) -eq $true)
{
    $msg = 'エクスポート先フォルダ「 ' + $vm_export_path + ' 」が既に存在するのでスクリプトを停止します'
    WriteLog($msg)
    exit
}
else {
    #エクスポート先ディレクトリの作成
    New-Item -Path $vm_export_path -ItemType Directory | Out-Null
}

#PowerCLI設定（11.5.0）
Set-PowerCLIConfiguration -Scope AllUsers -InvalidCertificateAction Ignore -ParticipateInCeip $false -Confirm:$false -WebOperationTimeoutSeconds 144000  | Out-Null

#移行対象分処理
foreach($i_vm in $vm_target)
{
    #エクスポート実行フラグ
    $export_f = 0

    #移行元vCenter接続
    WriteLog('移行元vCenter接続')
    Connect-VIServer -Server $source_vcenter -Protocol https -User $source_admin -Password $source_admin_pass | Out-Null

    #VMオブジェクト取得
    $source_vmlist = Get-VM -Server $source_vcenter
    foreach($source_vm in $source_vmlist)
    {
        #ターゲットの仮想マシン名が移行元にあれば
        if($source_vm.Name -eq $i_vm)
        {
            #電源ステータス確認
            #ステータスがpoweroffだったらOK
            if($source_vm.PowerState -ne 'PoweredOff')
            {
                WriteLog($source_vm.Name + 'は電源がオフではありません')
                $export_f = 1
            }
            else {
                WriteLog($source_vm.Name + 'は電源がオフです')
            }

            #スナップショット確認
            #スナップショットがなければOK
            if((Get-Snapshot -vm $source_vm | Measure-Object).Count -eq 0)
            {
                WriteLog($source_vm.Name + 'はスナップショットはありません')
            }
            else {
                WriteLog($source_vm.Name + 'はスナップショットがあります')
                $export_f = 1
            }

            #CDドライブ状態確認
            #メディアがなければOK
            $vmcd = $null
            $vmcd = Get-CDDrive -VM $source_vm | Select-Object Name,IsoPath,HostDevice,RemoteDevice | Sort-Object Name
            #CD有無フラグ初期化
            $cd_f = 0
            foreach($cd in $vmcd)
            {
                #CD有無判定
                if(-Not([string]::IsNullOrEmpty($cd.IsoPath + $cd.HostDevice + $cd.RemoteDevice)))
                {
                    #CD有無フラグ設定
                    $cd_f = 1
                }
            }
            #
            #CD有り
            if($cd_f -eq 1)
            {
                WriteLog($source_vm.Name + 'はメディアがあります')
                $export_f = 1
            }
            #CDなし
            else {
                WriteLog($source_vm.Name + 'はメディアはありません')
            }

            #エクスポートチェックが通ったら
            if($export_f -eq 0)
            {
                #仮想マシンエクスポート
                $msg = $source_vm.Name + 'のエクスポート開始'
                WriteLog($msg)
                Export-VApp -Destination $vm_export_path -VM $source_vm -Format Ovf | Out-Null
                $msg = $source_vm.Name + 'のエクスポート終了'
                WriteLog($msg)

                #移行元vCenter切断
                WriteLog('移行元vCenter切断')
                Disconnect-VIServer -Server $source_vcenter -Force -Confirm:$false
        
                #移行先vCenterへ接続
                WriteLog('移行先vCenter接続')
                Connect-VIServer -Server $destination_vcenter -Protocol https -User $destination_admin -Password $destination_admin_pass | Out-Null

                #移行先仮想マシン重複チェック
                $destination_vmlist = Get-vm -Server $destination_vcenter
                foreach($destination_vm in $destination_vmlist)
                {
                    if($source_vm.Name -eq $destination_vm.Name)
                    {
                        $dep_flag = 1
                        $destination_dep_vm += $source_vm.Name
                    }
                }

                #移行先に重複がなければインポート
                if($dep_flag -eq 0)
                {
                    #仮想マシンインポート
                    $myDatastore = Get-Datastore -Name $destination_ds -Server $destination_vcenter
                    $vmHost = Get-VMHost -Name $destination_vmhost
                    $ovf_path = $vm_export_path + '\' + $source_vm.Name + '\' + $source_vm.Name + '.ovf'
            
                    $msg = $i_vm + 'のインポート開始'
                    WriteLog($msg)
                    $vmHost | Import-vApp -Source $ovf_path -Datastore $myDatastore -Force | Out-Null
                    $msg = $i_vm + 'のインポート終了'
                    WriteLog($msg)
                }
                else {
                    WriteLog($source_vm.Name + 'は移行先に同一仮想マシン名があります')
                }
                #移行先vCenter切断
                WriteLog('移行先vCenter切断')
                Disconnect-VIServer -Server $destination_vcenter -Force -Confirm:$false
            }
            else {
                WriteLog($source_vm.Name + 'はエクスポートせずに次の仮想マシンへスキップします')
            }
        }
    }
}

#インポートしなかったリスト
if($destination_dep_vm -eq 0)
{
    WriteLog('エクスポートが完了した仮想マシンでインポートをスキップした仮想マシンはありません')
}
else {
    $msg = 'エクスポート完了後、移行先仮想マシン名重複によりインポートしなかった仮想マシン : ' + $destination_dep_vm
    WriteLog($msg)      
}
#

WriteLog('スクリプトの終了')
###

