# KB: Password reset and MFA / token issues

**Category:** Identity and access | **Audience:** Service Desk (Tier 1)

## Security rules (always)
- Verify the caller's identity using the approved verification steps before any reset
- Never ask for a user's current password
- Never share or send temporary passwords in an unprotected channel
- Log every reset against a ticket

## Password reset (Active Directory)
1. Verify the user's identity.
2. In Active Directory Users and Computers, find the account and check whether it is **locked out** or **disabled**.
3. Unlock the account if needed, or use **Reset Password**.
4. Set a temporary password and tick **User must change password at next logon**.
5. Give the temporary password through the approved secure method.
6. Ask the user to sign in and confirm. If they use VPN or a mobile device, remind them to update the saved password to avoid repeat lockouts.

## Repeated lockouts
Common causes: old saved password on a phone, mapped drive or scheduled task. Check the lockout source before resetting again.

## MFA / token issues
- Authenticator not prompting: check the phone's time/date and internet connection
- New phone: follow the approved MFA re-registration process after identity verification
- Lost token: disable and re-issue per procedure, and log the change

## Escalate when
- The account cannot be unlocked or keeps locking with an unknown source
- A privileged account or a suspected compromise is involved (escalate to Security first)
