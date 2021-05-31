<#
.SYNOPSIS
  Place openrc contents in env vars.
.DESCRIPTION
  This script will read the openrc file with your clouds credentials and place
  them in your enviroment variables. If you don't provide any file it will
  assume you are using CloudVPS and ask for a project, username and password.
.PARAMETER openrcfile
  The openrc file you can download from Horizon
.NOTES
  Version:        1.0
  Author:         Cees Moerkerken
  Creation Date:  9-4-2019
  Purpose/Change: Place openrc contents in env vars.
  
.EXAMPLE
  Source-OpenRC.ps1 C:\johnd-openrc.sh
.LINK
   http://virtu-on.nl
#>

# Unset all OS_ env variables to prevent v2/v3 problems
Get-ChildItem env:OS_* | remove-item

# Define some variables
$openrc = $args[0]
$error = "The file you specified doesn't seem to be a valid OpenRC file"
Write-Host $args.count

If ($args.count -lt 1) {
    Set-Item -Path Env:OS_AUTH_URL "https://identity.openstack.cloudvps.com/v3"
    Set-Item -Path Env:OS_INTERFACE "public"
    Set-Item -Path Env:OS_IDENTITY_API_VERSION "3"
    Set-Item -Path Env:OS_PROJECT_DOMAIN_NAME "Default"
    Set-Item -Path Env:OS_USER_DOMAIN_NAME "Default "
    Set-Item -Path Env:OS_REGION_NAME "AMS"
    Write-Host "No openrc file argument found, using CloudVPS defaults."
}

ElseIf ($args.count -gt 1) {
    Write-Host "Please provide a single OpenRC file as argument."
    Exit
}

ElseIf (-Not (Test-Path $args[0])) {
    Write-Host "The OpenRC file you specified doesn't exist!"
    Exit
}

Else {
    # Loop over lines that start with export
    foreach($line in Get-Content $openrc) {
        if($line -match "^export.*"){
            # Strip export
            $stripped_line=([string]($line)).Replace("export ","")
            $key=([string]($stripped_line)).Split("=")[0].Replace("`"","")
            $value=([string]($line)).Split("=")[1].Replace("`"","")
            Write-Host $key $value
            Set-Item -Path Env:$key $value
        }

    }
}

If (-Not (test-path Env:OS_PROJECT_ID)) {
    $project = Read-Host 'Please enter your 32 character OpenStack project ID or exact project name'

    if ($project -eq [string]::empty) {
        Write-Host "No project provided, authentication will fail, goodbye"
        Exit
    }
    ElseIf ($project -match "[a-z0-9]{32}"){
        Set-Item -Path Env:OS_PROJECT_ID $project
    }
    Else {
        Set-Item -Path Env:OS_PROJECT_NAME $project
    }
}

If (-Not (test-path Env:OS_USERNAME)) {
    $username = Read-Host 'Please enter your OpenStack Username'

    if ($username -eq [string]::empty) {
        Write-Host "No Username provided, authentication will fail, goodbye"
        Exit
    }
    Else {
        Set-Item -Path Env:OS_USERNAME $username
    }
}

If (-Not (test-path env:OS_PASSWORD)) {
    $password = Read-Host 'Please enter your OpenStack Password' -AsSecureString

    if ($password -eq [string]::empty) {
        Write-Host "No Password provided, authentication will fail, goodbye"
        Exit
    }
    Else {
        $env:OS_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
    }
}
