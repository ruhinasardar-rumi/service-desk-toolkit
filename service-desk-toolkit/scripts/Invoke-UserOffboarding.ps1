<#
.SYNOPSIS
    Offboards a user in Active Directory (User Access Management / offboarding).

.DESCRIPTION
    Steps performed:
      1. Disables the account
      2. Removes the user from all groups except the primary group (Domain Users)
      3. Records the ticket number and date in the account description
      4. Moves the account to a Disabled Users OU
      5. Logs each action to a CSV file

    Supports -WhatIf so the change can be reviewed and approved first.

.EXAMPLE
    .\Invoke-UserOffboarding.ps1 -SamAccountName jane.doe -TicketNumber INC0012345 `
        -DisabledOuPath "OU=Disabled Users,DC=lab,DC=local" -WhatIf

.NOTES
    Requires the ActiveDirectory module (RSAT). Designed and intended for use in a lab domain.
    Mailbox, licence and data-retention steps follow company policy and are outside this script.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)][string]$SamAccountName,
    [Parameter(Mandatory)][string]$TicketNumber,
    [Parameter(Mandatory)][string]$DisabledOuPath,
    [string]$LogPath = ".\offboarding-log.csv"
)

Import-Module ActiveDirectory -ErrorAction Stop

function Write-Log {
    param([string]$Action, [string]$Result, [string]$Details = "")
    [pscustomobject]@{
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        Ticket    = $TicketNumber
        User      = $SamAccountName
        Action    = $Action
        Result    = $Result
        Details   = $Details
    } | Export-Csv -Path $LogPath -NoTypeInformation -Append
}

$user = Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -Properties MemberOf, Description
if (-not $user) {
    Write-Error "User $SamAccountName not found."
    Write-Log "Lookup" "Failed" "User not found"
    return
}

if ($PSCmdlet.ShouldProcess($SamAccountName, "Disable account")) {
    Disable-ADAccount -Identity $user
    Write-Log "Disable" "Success"
}

foreach ($groupDn in $user.MemberOf) {
    if ($PSCmdlet.ShouldProcess($SamAccountName, "Remove from group $groupDn")) {
        Remove-ADGroupMember -Identity $groupDn -Members $user -Confirm:$false
        Write-Log "RemoveGroup" "Success" $groupDn
    }
}

if ($PSCmdlet.ShouldProcess($SamAccountName, "Update description and move to $DisabledOuPath")) {
    $note = "Disabled $(Get-Date -Format 'yyyy-MM-dd') per ticket $TicketNumber"
    Set-ADUser -Identity $user -Description $note
    Move-ADObject -Identity $user.DistinguishedName -TargetPath $DisabledOuPath
    Write-Log "Move" "Success" $DisabledOuPath
}

Write-Host "Offboarding steps complete for $SamAccountName. Log: $LogPath"
