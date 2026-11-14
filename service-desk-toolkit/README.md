# Service Desk Toolkit

A small portfolio project covering everyday **IT Service Desk, User Access Management and reporting** tasks: automating account onboarding and offboarding, documenting support procedures, and reporting on ticket data.

> **Note:** All data is fictional sample data. The PowerShell scripts are written for a **lab Active Directory domain** and support `-WhatIf` so every change can be reviewed first.

## What is in this repo

| Folder | Contents | Skills shown |
|---|---|---|
| `scripts/New-UserOnboarding.ps1` | Creates AD accounts from a CSV, sets a temporary password, forces a password change, adds role groups, writes an audit log | PowerShell, Active Directory, onboarding, access control |
| `scripts/Invoke-UserOffboarding.ps1` | Disables an account, removes group memberships, records the ticket number, moves it to a Disabled OU, logs each step | Offboarding, access administration, audit logging |
| `scripts/ticket_report.py` | Reads a ticket export and reports volume, SLA compliance, first-contact resolution and recurring issues | Python, reporting, problem management |
| `sql/ticket_queries.sql` | Example reporting queries on a ticket table | SQL, reporting |
| `knowledge-base/` | VPN troubleshooting, password reset and MFA, and incident triage and escalation articles | Knowledge base documentation, ITSM practices |
| `data/` | Sample new-hire and ticket CSV files (fictional) | |

## Quick start

**Ticket report (Python 3, no extra packages)**
```bash
cd scripts
python ticket_report.py ../data/sample_tickets.csv > report.md
```

**Onboarding preview (Windows, RSAT ActiveDirectory module, lab domain)**
```powershell
cd scripts
.\New-UserOnboarding.ps1 -CsvPath ..\data\new_hires.csv -OuPath "OU=Staff,DC=lab,DC=local" -WhatIf
```
Remove `-WhatIf` to apply the changes in a lab.

**Offboarding preview**
```powershell
.\Invoke-UserOffboarding.ps1 -SamAccountName alex.morgan -TicketNumber INC0012345 `
    -DisabledOuPath "OU=Disabled Users,DC=lab,DC=local" -WhatIf
```

## Design choices
- **Approval before change:** `-WhatIf` support so actions can be reviewed
- **Audit trail:** each action is logged with the ticket number
- **Security:** temporary passwords are random, are not written to logs, and must be changed at first logon
- **Documentation first:** procedures are written as knowledge base articles so issues can be resolved consistently

## Possible next steps
- Add Microsoft Entra ID / Microsoft 365 licensing steps
- Add a Power Automate approval flow for onboarding requests
- Build a Power BI dashboard from the ticket report data
