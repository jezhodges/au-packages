param($Name = $null)
cd $PSScriptRoot

#import-module ..\au -force

$options = @{
    Timeout = 100
    Push    = $true
    Threads = 10

    Mail = @{
        To       = 'miodrag.milic@gmail.com'
        Server   = 'smtp.gmail.com'
        UserName = 'miodrag.milic@gmail.com'
        Password = if (Test-Path $PSScriptRoot\mail_pass) { gc $PSScriptRoot\mail_pass } else {''}
        Port     = 587
        EnableSsl= $true
    }

    Script = { param($Phase, $Info)
        if ($Phase -ne 'END') { return }

        save-runinfo
        save-gist
        git
    }
}

function save-runinfo {
    "Saving run info"
    $Info | Export-CliXML $PSScriptRoot\update_results.xml
}

function save-gist {
    "Saving to gist"
    if (!(gcm gist.bat -ea 0)) { "  Error: No gist.bat found: gem install gist"; return }

    $gist_id = '44c248fc1e58059e09a4f760928425f0'

    #gc $PSScriptRoot\update_results.xml | gist.bat --filename info.xml --update $gist_id

    $log = @()
    $log += "# Update-AUPackages`n"
    $log += "`n**Time:** $($info.startTime)"
    $log += "`n**Packages:** [majkinetor@chocolatey](https://chocolatey.org/profiles/majkinetor)"
    $log += "`n**Git repository:** https://github.com/majkinetor/chocolatey"
    $log += "`nThis file is automatically generated by the [update_all.ps1](https://github.com/majkinetor/chocolatey/blob/master/update_all.ps1) script using the [AU module](https://github.com/majkinetor/au)."
    if ($Info.error_count.total) { $log +="`n<img src='https://cdn0.iconfinder.com/data/icons/shift-free/32/Error-128.png' width='50'> **LAST RUN HAD $($info.error_count.total) [ERRORS](#errors) !!!**" }
    else { $log += "`n<img src='http://www.iconsdb.com/icons/preview/tropical-blue/ok-xxl.png' width='50'> Last run was OK" }

    $log += '```'
        $log += $Info.stats + "`n" + ($Info.result | ft)
    $log += '```'

    if ($info.error_count.total) {
        $log += "## Errors`n"
        $log += '```'
            $log += $info.error_info
        $log += '```'
    }

    $log | gist.bat --filename _update_results.md --update $gist_id
}

function git() {
    $pushed = $Info.results | ? Pushed
    if (!$pushed) { return }

    pushd $PSScriptRoot

    "`nExecuting git pull"
    git pull

    "Commiting updated packages to git repository"
    $pushed | % { git add $_.PackageName }
    git commit -m "UPDATE BOT: $($pushed.length) packages updated"

    "`nPushing git"
    git push
    popd
}

updateall -Name $Name -Options $options | ft
$global:updateall = Import-CliXML $PSScriptRoot\update_results.xml

