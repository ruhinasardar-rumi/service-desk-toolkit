# KB: Troubleshooting VPN connection problems (GlobalProtect / Cisco AnyConnect)

**Applies to:** Windows and macOS users connecting remotely
**Category:** Remote access | **Audience:** Service Desk (Tier 1)

## Symptoms
- VPN client will not connect or keeps disconnecting
- "Authentication failed" or MFA prompt never arrives
- Connected, but internal sites or file shares do not load

## Before you start
- Confirm the user's name, device and location, and log the incident with these details
- Ask: did it work before? What changed (password change, new device, new network)?

## Steps
1. **Check the internet connection.** Ask the user to open a public website. If it fails, the issue is the local network (restart the router, try another network or hotspot).
2. **Confirm the correct portal/gateway address** is entered in the VPN client.
3. **Check credentials.** If the account is locked or the password expired, verify the user's identity using the approved process, then unlock or reset it.
4. **Check the second factor (RSA / MFA).** Confirm the token or authenticator is working and that the device time is correct. If the token is lost or out of sync, follow the token reset procedure.
5. **Restart the VPN client**, then sign out and back in. Reinstall the client only if restarting does not help.
6. **Test DNS and routing.** If the VPN connects but internal resources fail, run `ipconfig /all` (Windows) or `scutil --dns` (macOS) and confirm an internal DNS server is assigned. Test with `nslookup` and `ping`.
7. **Check for conflicts.** Disable other VPN clients, check that the firewall or security software is not blocking the client, and confirm the OS is up to date.

## Escalate to Network / Infrastructure when
- Several users report the same problem (possible outage, so raise a major incident)
- The account and token are valid but the gateway rejects the connection
- Logs show certificate or gateway errors

## Information to include when escalating
User, device, OS, client version, error message or screenshot, time of issue, network type, steps already tried.

## Closing the ticket
Confirm with the user that they are connected and can reach their resources, record the fix, and link this article.
