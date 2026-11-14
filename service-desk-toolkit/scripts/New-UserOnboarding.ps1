<#
.SYNOPSIS
    Creates Active Directory accounts for new hires from a CSV file (User Access Management / onboarding).

.DESCRIPTION
    For each row in the CSV the script:
      1. Builds a username (firstname.lastname) and checks it does not already exist
      2. Creates the account in the chosen OU with a random temporary password
      3. Forces a password change at first logon
      4. Adds the user to the groups listed for their role (separated by ;)
      5. Writes every action (created / skipped / failed) to a CSV log for audit purposes

    Supports -WhatIf so the run can be reviewed and approved before any change is made.
    Temporary passwords are NOT written to the log. They are shown once on screen
    so they can be handed over through the approved secure process.

.PARAMETER CsvPath
    CSV with columns: FirstName, LastName, Department, Title, Manager, Groups, TicketNumber

.PARAMETER OuPath
    Distinguished name of the target OU, e.g. "OU=Staff,DC=lab,DC=local"

.EXAMPLE
    .\New-UserOnboarding.ps1 -CsvPath ..\data\new_hires.csv -OuPath "OU=Staff,DC=lab,DC=local" -WhatIf

.NOTES
    Requires the ActiveDirectory module (RSAT) and rights to create users.
    Designed and intended for use in a lab domain. Review and test before using anywhere else.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)][string]$CsvPath,
    [Parameter(Mandatory)][string]$OuPath,
    [string]$UpnSuffix = "lab.local",
    [string]$LogPath = ".\onboarding-log.csv"
)

Import-Module ActiveDirectory -ErrorAction Stop

function New-TempPassword {
    $upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ'.ToCharArray()
    $lower = 'abcdefghijkmnopqrstuvwxyz'.ToCharArray()
    $digit = '23456789'.ToCharArray()
    $symbol = '!@#$%*'.ToCharArray()
    $chars = @(
        (Get-Random -InputObject $upper),
        (Get-Random -InputObject $lower),
        (Get-Random -InputObject $digit),
        (Get-Random -InputObject $symbol)
    )
    $all = $upper + $lower + $digit + $symbol
    1..10 | ForEach-Object { $chars += (Get-Random -InputObject $all) }
    -join ($chars | Get-Random -Count $chars.Count)
}

$log = New-Object System.Collections.Generic.List[object]

foreach ($row in Import-Csv -Path $CsvPath) {
    $sam = ("{0}.{1}" -f $row.FirstName.Trim(), $row.LastName.Trim()).ToLower()
    $entry = [ordered]@{
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        Ticket    = $row.TicketNumber
        User      = $sam
        Action    = ""
        Result    = ""
        Details   = ""
    }

    try {
        if (Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue) {
            $entry.Action = "Create"; $entry.Result = "Skipped"
            $entry.Details = "Account already exists"
            Write-Warning "$sam already exists - skipped"
            $log.Add([pscustomobject]$entry); continue
        }

        $tempPassword = New-TempPassword
        $securePassword = ConvertTo-SecureString $tempPassword -AsPlainText -Force

        if ($PSCmdlet.ShouldProcess($sam, "Create AD user in $OuPath")) {
            $params = @{
                Name                  = "$($row.FirstName) $($row.LastName)"
                GivenName             = $row.FirstName
                Surname               = $row.LastName
                SamAccountName        = $sam
                UserPrincipalName     = "$sam@$UpnSuffix"
                Department            = $row.Department
                Title                 = $row.Title
                Path                  = $OuPath
                AccountPassword       = $securePassword
                Enabled               = $true
                ChangePasswordAtLogon = $true
                Description           = "Created per ticket $($row.TicketNumber)"
            }
            New-ADUser @params

            if ($row.Manager) {
                $mgr = Get-ADUser -Filter "SamAccountName -eq '$($row.Manager)'" -ErrorAction SilentlyContinue
                if ($mgr) { Set-ADUser -Identity $sam -Manager $mgr.DistinguishedName }
            }

            foreach ($group in ($row.Groups -split ';' | Where-Object { $_.Trim() })) {
                Add-ADGroupMember -Identity $group.Trim() -Members $sam
            }

            $entry.Action = "Create"; $entry.Result = "Success"
            $entry.Details = "Groups: $($row.Groups)"
            Write-Host "Created $sam - temporary password (hand over securely): $tempPassword"
        }
        else {
            $entry.Action = "Create"; $entry.Result = "WhatIf"
            $entry.Details = "No changes made"
        }
    }
    catch {
        $entry.Action = "Create"; $entry.Result = "Failed"
        $entry.Details = $_.Exception.Message
        Write-Error "Failed for ${sam}: $($_.Exception.Message)"
    }
    $log.Add([pscustomobject]$entry)
}

$log | Export-Csv -Path $LogPath -NoTypeInformation -Append
Write-Host "Done. Log written to $LogPath"
