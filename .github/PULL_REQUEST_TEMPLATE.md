## Description

<!-- What does this PR do? If it adds a tool, link to the tool's repo. If it fixes something, describe the bug. -->



## Type of Change

- [ ] 🛠️ New tool addition
- [ ] 🐛 Bug fix (broken install step, dead link, failed build)
- [ ] ⚙️ System fix (GRUB, SMB, nmap scripts, hypervisor detection, etc.)
- [ ] 📝 Documentation (README, CONTRIBUTING, comments)
- [ ] ♻️ Refactor (no functional change)
- [ ] 🚨 Other (describe above)

## If adding a new tool

- **Tool name:**
- **Upstream link:**
- **Which STEP / category does it belong to?**
- **Which wrapper(s) did you use?** (`apt_install`, `pip_install`, `git_clone`, `make_wrapper`, etc. — see [CONTRIBUTING.md](../CONTRIBUTING.md))

## Testing

<!-- This project only works if it never crashes halfway. Please confirm you actually ran it. -->

- [ ] Ran `bash -n funkmykali.sh` — no syntax errors
- [ ] Ran the full script end-to-end on a real Kali VM (not just the section I changed)
- [ ] Tested on:
  - Kali variant/version: <!-- e.g. kali-linux-default 2024.3 -->
  - Environment: <!-- VirtualBox / VMware / QEMU / WSL / Docker / bare metal -->
- [ ] Confirmed the tool/fix appears correctly in the final verification summary
- [ ] No new errors introduced in `/var/log/funkmykali.log` for unrelated steps

## Checklist

- [ ] I used the existing safe wrappers — no bare `apt install`, `pip install`, or `git clone`
- [ ] My `git_clone` call is idempotent (safe to re-run without failing)
- [ ] I added the tool's command name to the `CRITICAL=(...)` verification array (if applicable)
- [ ] I updated `README.md` to list the new tool/change (if applicable)
- [ ] I added a note to `README-manual-installs.txt` if this requires a manual step (Docker, GUI, license)
- [ ] My commit messages are specific (not "update" or "fix stuff")
- [ ] This PR does one logical thing (not a bundle of unrelated changes)

## Related Issue

<!-- Closes #123, or "N/A" if this wasn't filed as an issue first -->



## Scope Confirmation

- [ ] This change is for **authorized** penetration testing / certification labs (HTB, OffSec, TCM Security, INE, TryHackMe) and complies with [CODE_OF_CONDUCT.md](../CODE_OF_CONDUCT.md)
