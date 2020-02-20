<#
start-job_01.ps1
202002202216
PowerCLI
https://www.powershellgallery.com/packages/VMware.PowerCLI/11.5.0.14912921
#>

#実行ポリシー設定
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned

function Create-File(){
    $logtime = Get-Date -Format "yyyyMMddHHmmss"
    $logfile = $logtime + '_log.txt'
    Start-Sleep -Seconds 30
    Get-Date -Format "yyyyMMddHHmmss" | Add-Content $logfile -Encoding Default
}


Start-Job {Create-File}