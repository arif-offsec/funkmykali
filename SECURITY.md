# Security Policy

## Supported Versions

funkmykali is a single, continuously-updated script rather than a versioned release train. Only the latest commit on `main` is supported. If you're running an older copy you cloned a while back, please `git pull` before reporting an issue — it may already be fixed.

## Reporting a Vulnerability

Please **do not** open a public GitHub issue for security reports.

Instead, use one of these private channels:

1. **GitHub Private Vulnerability Reporting** (preferred) — go to the [Security tab](https://github.com/arif-offsec/funkmykali/security) of this repo and click **"Report a vulnerability."**
2. **Direct message** via [@arif-offsec](https://github.com/arif-offsec) on GitHub if the Security tab isn't available to you.

Please include:
- A description of the issue and its potential impact
- Steps to reproduce (which section/step of the script, on what Kali variant)
- Any relevant log output from `/var/log/funkmykali.log`

This project is maintained by one person in their spare time. I'll do my best to acknowledge reports within a few days and patch confirmed issues promptly, but please be patient.

## What Counts as a Vulnerability Here

funkmykali runs as **root** and downloads/executes third-party scripts, binaries, and repos from dozens of external sources. Given that, the vulnerability classes that actually matter for *this project* are:

- **Supply-chain issues** — a malicious PR that swaps a legitimate tool URL for a typosquatted or attacker-controlled one
- **Insecure retrieval** — a download that should be pinned or checksum-verified but isn't, in a way that meaningfully increases MITM risk
- **Command injection** in the script's own logic (e.g. unsanitized input reaching `eval`, `bash -c`, etc.)
- **Unsafe file permissions** on anything written to `/opt/tools`, `/usr/local/bin`, or `/etc/profile.d` that could allow local privilege escalation by a non-root user on a shared box
- **Credential exposure** — secrets, tokens, or keys accidentally logged or hardcoded

## Out of Scope

- **Vulnerabilities in the tools funkmykali installs** (nmap, Metasploit, BloodHound, etc.) — please report those upstream to the respective project.
- **"This lets me install hacking tools"** — that is the stated purpose of this project, not a vulnerability. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for acceptable use.
- **Missing upstream GPG/checksum verification** for third-party tools that don't provide one themselves — this is a known limitation of curl/wget-based installers in general. PRs that add verification where upstream does provide it are welcome as normal contributions, not required as security reports.

## A Note on Trust

This script requires root and modifies system files (GRUB, SMB config, sources.list, systemd services). As with any script that does this — `pimpmykali` included — you should **read through `funkmykali.sh` before running it**, especially if you're running it on anything other than a disposable VM. That's just good practice for any installer that asks for `sudo`, not something specific to this project.

---

Thanks for helping keep funkmykali safe for the community using it. 🔴
