<div align="center">

```
███████╗██╗   ██╗███╗   ██╗██╗  ██╗███╗   ███╗██╗   ██╗██╗  ██╗ █████╗ ██╗     ██╗
██╔════╝██║   ██║████╗  ██║██║ ██╔╝████╗ ████║╚██╗ ██╔╝██║ ██╔╝██╔══██╗██║     ██║
█████╗  ██║   ██║██╔██╗ ██║█████╔╝ ██╔████╔██║ ╚████╔╝ █████╔╝ ███████║██║     ██║
██╔══╝  ██║   ██║██║╚██╗██║██╔═██╗ ██║╚██╔╝██║  ╚██╔╝  ██╔═██╗ ██╔══██║██║     ██║
██║     ╚██████╔╝██║ ╚████║██║  ██╗██║ ╚═╝ ██║   ██║   ██║  ██╗██║  ██║███████╗██║
╚═╝      ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝     ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝
```

**Zero-error, system-wide Kali Linux setup script for penetration testing certifications.**

[![Kali Linux](https://img.shields.io/badge/Kali%20Linux-2024%2B-blue?logo=kalilinux)](https://www.kali.org/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Tools](https://img.shields.io/badge/Tools-100%2B-red)]()
[![HTB Modules](https://img.shields.io/badge/HTB%20Modules-28%2F28-brightgreen)]()
[![GitHub Stars](https://img.shields.io/github/stars/arif-offsec/funkmykali?style=social)](https://github.com/arif-offsec/funkmykali)

</div>

---

## What is funkmykali?

A single command that turns **any** Kali Linux variant — minimal, default, WSL, Docker, cloud, or VM — into a fully equipped, cert-ready penetration testing environment.

### Why does it reinstall tools already in Kali?

Kali ships in multiple variants. `kali-linux-everything` has most tools. But `kali-linux-minimal`, WSL Kali, Docker Kali, and cloud instances have almost nothing. funkmykali works on **all of them** from scratch.

Even on a full Kali install, funkmykali:
- **Upgrades** tools to their latest versions (apt packages can lag months behind)
- **Fixes** known broken tools (`http-shellshock.nse`, `clamav-exec.nse`, SMB config)
- **Installs** 50+ tools that are never in any Kali variant by default (Ligolo-ng, PlumHound, Ghidra, all Go tools, all Python CLI tools with zero pip conflicts)
- **Configures** the system (GRUB, power management, hypervisor additions, binfmt_misc, Neo4j, Metasploit DB)
- **Creates** system-wide wrappers so every tool works from any terminal session

**One command. Any Kali. Fully working. Guaranteed.**

---

## Certifications Covered

| Cert | Provider | Coverage |
|------|----------|----------|
| **CPTS** | Hack The Box | ✅ All 28 modules, 495 sections |
| **OSCP** | OffSec | ✅ Full |
| **PNPT** | TCM Security | ✅ Full |
| **PJPT** | TCM Security | ✅ Full |
| **eJPT** | INE Security | ✅ Full |
| **eCPPT** | INE Security | ✅ Full |
| **PT1** | TryHackMe | ✅ Full |
| **PT2** | TryHackMe | ✅ Full |

---

## Requirements

- Kali Linux 2024.x or newer (any variant — minimal, default, WSL, Docker, VM, cloud)
- Root / sudo access
- Active internet connection
- ~20–30 GB free disk space

---

## Usage

```bash
git clone https://github.com/arif-offsec/funkmykali.git
cd funkmykali
sudo bash funkmykali.sh
```

Reload your shell when done:

```bash
source /etc/profile.d/funkmykali.sh
```

---

## What Gets Installed & Configured

### System Fixes
- Kali signing key validation and repair
- `deb-src` and `non-free-firmware` enabled in sources
- GRUB: `mitigations=off` for VM performance
- SMB: `client min protocol = LANMAN1` for legacy Windows compatibility
- nmap scripts fixed: `http-shellshock.nse`, `clamav-exec.nse`
- `binfmt_misc` mounted for Windows `.exe` via Wine
- PC speaker beep silenced
- `hushlogin` set (suppresses login banner)
- LightDM: Kali-Dark theme applied
- SSH wide-compat config applied
- Qterminal: unlimited scrollback
- Power management disabled (XFCE + GNOME) — no sleep during long scans

### Hypervisor Detection & Guest Additions
Auto-detects the environment and installs:
- **VirtualBox** → `virtualbox-guest-x11`, `virtualbox-dkms`
- **VMware** → `open-vm-tools-desktop`, `fuse3`
- **QEMU/KVM** → `spice-vdagent`, `qemu-guest-agent`
- **Bare metal** → skips silently

### Network Scanning & Enumeration
`nmap` `masscan` `hping3` `arp-scan` `netdiscover` `fping` `p0f`

### Exploitation
`metasploit-framework` `searchsploit` `impacket` (full suite) `SPIKE`

### Web Application
`burpsuite` `zaproxy` `sqlmap` `nikto` `gobuster` `ffuf` `feroxbuster`
`wfuzz` `dirbuster` `dirb` `xsstrike` `commix` `linkfinder` `jwt_tool`
`gopherus` `arjun` `nuclei` `katana` `httpx` `httprobe`

### Active Directory
`bloodhound` `neo4j` `crackmapexec` `netexec` `evil-winrm` `kerbrute`
`responder` `impacket-secretsdump` `impacket-psexec` `impacket-GetNPUsers`
`impacket-GetUserSPNs` `certipy-ad` `ldapdomaindump` `mitm6` `coercer`
`PowerSploit` `PowerUpSQL` `Rubeus` `Certify` `Mimikatz` `Inveigh`
`BloodHound` `SharpHound` `ADRecon` `DonPAPI` `SprayingToolkit` `sprayhound`
`PlumHound` `o365spray`

### Password Attacks
`hydra` `medusa` `crowbar` `john` `hashcat` `cewl` `crunch`
`name-that-hash` `haiti` `pypykatz` `lsassy` `pcredz` `LaZagne`

### Privilege Escalation
`linpeas.sh` (all variants) `winpeas` (all variants) `lse.sh` `pspy64`
`PrivescCheck` `SharpUp` `BeRoot` `Snaffler` `lynis` `GTFOBLookup`
`PrintSpoofer64.exe` `GodPotato.exe` `JuicyPotato.exe`

### Pivoting & Tunneling
`ligolo-ng` (proxy + agent, Linux + Windows) `chisel` `proxychains4` `sshuttle`
`socat` `rpivot` `ptunnel-ng` `dnscat2-powershell` `pretender`

### Shells & Payloads
`villain` `hoaxshell` `penelope` `pwncat-cs` `nishang` `webshells` `msfvenom` `SET`

### Recon & OSINT
`subfinder` `amass` `dnsx` `dnsrecon` `theHarvester` `sublist3r`
`whatweb` `gowitness` `shodan` `username-anarchy` `o365spray`
`waybackrust` `httprobe` `assetfinder`

### Evasion
`Bashfuscator` `Invoke-DOSfuscation` `darkarmour`

### Reverse Engineering
`Ghidra` (latest from GitHub, with dark theme)

### Wordlists
`rockyou.txt` `SecLists` (full, at `/usr/share/seclists/`)

### Editors & Tools
`VSCode` `Sublime Text` `gedit` `Google Chrome`

### Reporting & Notes
`cherrytree` `flameshot`

---

## Tool Locations

| Location | Contents |
|----------|----------|
| `/usr/local/bin/` | All system-wide CLI wrappers |
| `/usr/bin/` | apt-installed tools |
| `/opt/tools/` | Cloned GitHub repositories |
| `/opt/tools/windows-binaries/` | Pre-compiled `.exe` files |
| `/opt/linpeas/` | All LinPEAS variants |
| `/opt/winpeas/` | All WinPEAS variants |
| `/opt/PlumHound/` | PlumHound |
| `/opt/ghidra/` | Ghidra |
| `/usr/share/wordlists/` | rockyou + standard lists |
| `/usr/share/seclists/` | SecLists (full) |
| `/var/log/funkmykali.log` | Full install log |

---

## After Running

```bash
# 1. Reload environment
source /etc/profile.d/funkmykali.sh

# 2. Start BloodHound
sudo systemctl start neo4j && bloodhound &

# 3. Initialise Metasploit DB
sudo msfdb init && msfconsole

# 4. Check manual install reminders
cat /opt/tools/README-manual-installs.txt

# 5. Reboot (recommended — applies GRUB and kernel changes)
sudo reboot
```

---

## Manual Installs (Docker / browser)

**SysReptor** — ★★★ Most recommended tool for the CPTS exam report ★★★
Includes HTB's official CPTS report template.
```bash
git clone https://github.com/syslifters/sysreptor.git
cd sysreptor/deploy && docker compose up -d
# Visit http://localhost:8000 → import HTB CPTS template
```

**Obsidian** — Note-taking used by most CPTS passers.
Download: https://obsidian.md/download

**Exegol** — Already installed. Run: `exegol install full`

---

## Useful Aliases

```bash
nmap-quick       # nmap -sV -sC -oA quickscan
nmap-full        # nmap -p- -sV -sC --open -oA fullscan
nmap-vuln        # nmap --script vuln -oA vulnscan
pyserver         # python3 -m http.server 80
smbserver        # impacket-smbserver share . -smb2support
rlnc             # rlwrap nc -lvnp
vpnip            # prints your tun0 IP
linpeas          # runs linpeas.sh
```

---

## HTB Penetration Tester Path — All 28 Modules

| # | Module |
|---|--------|
| 01 | Penetration Testing Process |
| 02 | Getting Started |
| 03 | Network Enumeration with Nmap |
| 04 | Footprinting |
| 05 | Information Gathering - Web Edition |
| 06 | Vulnerability Assessment |
| 07 | File Transfers |
| 08 | Shells & Payloads |
| 09 | Using the Metasploit Framework |
| 10 | Password Attacks |
| 11 | Attacking Common Services |
| 12 | Pivoting, Tunneling, and Port Forwarding |
| 13 | Active Directory Enumeration & Attacks |
| 14 | Using Web Proxies |
| 15 | Attacking Web Applications with Ffuf |
| 16 | Login Brute Forcing |
| 17 | SQL Injection Fundamentals |
| 18 | SQLMap Essentials |
| 19 | Cross-Site Scripting (XSS) |
| 20 | File Inclusion |
| 21 | File Upload Attacks |
| 22 | Command Injections |
| 23 | Web Attacks (HTTP Verb Tampering, IDOR, XXE) |
| 24 | Attacking Common Applications |
| 25 | Linux Privilege Escalation |
| 26 | Windows Privilege Escalation |
| 27 | Documentation & Reporting |
| 28 | Attacking Enterprise Networks |

---

## Sources

Tools sourced from:
- HTB Academy (all 28 modules + 495 sections)
- HTB Official Forums & Discord
- Reddit (`r/hackthebox`, `r/oscp`, `r/netsec`, `r/tryhackme`)
- Medium / InfoSec write-ups and CPTS exam reviews (2024–2026)
- Community cheatsheets and GitHub repos
- [pimpmykali](https://github.com/Dewalt-arch/pimpmykali) — system fix inspiration

---

## Contributing

PRs and issues welcome. If a tool is missing, broken, or a newer alternative exists — open a PR.

---

## Disclaimer

For authorised lab environments and your own systems only. Penetration testing without written permission is illegal. The author takes no responsibility for misuse.

---

## License

MIT — use freely, credit appreciated, contributions welcome.

---

<div align="center">
<b>Enumerate everything. Trust the process. 🔴</b><br><br>
<a href="https://github.com/arif-offsec/funkmykali">github.com/arif-offsec/funkmykali</a>
</div>
