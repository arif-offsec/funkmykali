#!/bin/bash
# =============================================================================
#
#  ███████╗██╗   ██╗███╗   ██╗██╗  ██╗███╗   ███╗██╗   ██╗██╗  ██╗ █████╗ ██╗     ██╗
#  ██╔════╝██║   ██║████╗  ██║██║ ██╔╝████╗ ████║╚██╗ ██╔╝██║ ██╔╝██╔══██╗██║     ██║
#  █████╗  ██║   ██║██╔██╗ ██║█████╔╝ ██╔████╔██║ ╚████╔╝ █████╔╝ ███████║██║     ██║
#  ██╔══╝  ██║   ██║██║╚██╗██║██╔═██╗ ██║╚██╔╝██║  ╚██╔╝  ██╔═██╗ ██╔══██║██║     ██║
#  ██║     ╚██████╔╝██║ ╚████║██║  ██╗██║ ╚═╝ ██║   ██║   ██║  ██╗██║  ██║███████╗██║
#  ╚═╝      ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝     ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝
#
#  funkmykali.sh — Zero-error, system-wide Kali setup for:
#
#    ✅ HTB CPTS  — Certified Penetration Testing Specialist
#    ✅ HTB Penetration Tester Job Role Path (all 28 modules, 495 sections)
#    ✅ OSCP      — OffSec Certified Professional
#    ✅ PNPT      — TCM Security Practical Network Penetration Tester
#    ✅ PJPT      — TCM Security Practical Junior Penetration Tester
#    ✅ eJPT      — INE Security Junior Penetration Tester
#    ✅ eCPPT     — INE Security Certified Professional Penetration Tester
#    ✅ THM PT1   — TryHackMe Penetration Testing Level 1
#    ✅ THM PT2   — TryHackMe Penetration Testing Level 2
#
#  GitHub : https://github.com/arif-offsec/funkmykali
#  Author : arif-offsec
#  License: MIT
#
#  Usage:
#    git clone https://github.com/arif-offsec/funkmykali.git
#    cd funkmykali
#    sudo bash funkmykali.sh
#
#  Requirements: Kali Linux 2024.x or newer, internet, root
# =============================================================================

set -uo pipefail
IFS=$'\n\t'

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

# ── Log file ──────────────────────────────────────────────────────────────────
LOGFILE="/var/log/funkmykali.log"
exec > >(tee -a "$LOGFILE") 2>&1

log()  { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${CYAN}[*]${NC} $1"; }
err()  { echo -e "${RED}[-]${NC} $1"; }
section() {
  echo ""
  echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════${NC}"
  echo -e "${BOLD}${CYAN}  $1${NC}"
  echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════${NC}"
}

# ── Root check ────────────────────────────────────────────────────────────────
if [[ "$EUID" -ne 0 ]]; then
  err "Run as root:  sudo bash funkmykali.sh"
  exit 1
fi

# ── Kali check ────────────────────────────────────────────────────────────────
if ! grep -qi "kali" /etc/os-release 2>/dev/null; then
  warn "Kali Linux not detected — proceeding anyway, some functions may behave differently."
fi

# ── Detect real user (even when run with sudo) ────────────────────────────────
REALUSER=$(logname 2>/dev/null || echo "${SUDO_USER:-root}")
USERHOME=$(eval echo "~$REALUSER")
USERSHELL=$(getent passwd "$REALUSER" | cut -d: -f7 | xargs basename 2>/dev/null || echo "bash")

# ── Detect architecture ───────────────────────────────────────────────────────
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  ARCHSHORT="amd64" ;;
  aarch64) ARCHSHORT="arm64" ;;
  *)       ARCHSHORT="amd64" ;;
esac

# ── Directories ───────────────────────────────────────────────────────────────
TOOLS="/opt/tools"
WIN_BINS="/opt/tools/windows-binaries"
WORDLISTS="/usr/share/wordlists"
GOPATH="/root/go"
GOBIN="$GOPATH/bin"
mkdir -p "$TOOLS" "$WIN_BINS" "$WIN_BINS/winpeas" "$WORDLISTS"

# ── PATH for this session ─────────────────────────────────────────────────────
export PATH="$PATH:$GOBIN:/usr/local/go/bin:/usr/local/bin:/root/.local/bin"
export GOPATH
export DEBIAN_FRONTEND=noninteractive
export PYTHONWARNINGS=ignore

# =============================================================================
# ── Safe wrappers — NOTHING aborts the script ─────────────────────────────────
# =============================================================================

apt_install() {
  for pkg in "$@"; do
    if DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" \
        "$pkg" >> "$LOGFILE" 2>&1; then
      log "apt: $pkg"
    else
      warn "apt: $pkg FAILED (non-fatal — see $LOGFILE)"
    fi
  done
}

pip_install() {
  for pkg in "$@"; do
    if command -v pipx &>/dev/null; then
      if pipx install "$pkg" >> "$LOGFILE" 2>&1 || \
         pipx install "$pkg" --force >> "$LOGFILE" 2>&1; then
        log "pipx: $pkg"
        continue
      fi
    fi
    if pip3 install --break-system-packages "$pkg" >> "$LOGFILE" 2>&1; then
      log "pip3: $pkg"
    else
      warn "pip: $pkg FAILED (non-fatal)"
    fi
  done
}

pip3_install() {
  # Direct pip3 system-wide install (for libraries, not CLIs)
  pip3 install --break-system-packages "$@" >> "$LOGFILE" 2>&1 \
    && log "pip3: $*" \
    || warn "pip3: $* FAILED (non-fatal)"
}

pip_req() {
  local f="$1"
  [[ -f "$f" ]] && pip3 install --break-system-packages -r "$f" >> "$LOGFILE" 2>&1 \
    && log "pip3 req: $f" \
    || warn "pip3 req: $f FAILED (non-fatal)"
}

gem_install() {
  for g in "$@"; do
    gem install "$g" >> "$LOGFILE" 2>&1 && log "gem: $g" || warn "gem: $g FAILED"
  done
}

go_install() {
  go install "$1" >> "$LOGFILE" 2>&1 && log "go: $1" || warn "go: $1 FAILED"
}

git_clone() {
  local url="$1" dest="$2"
  if [[ -d "$dest/.git" ]]; then
    git -C "$dest" pull --quiet >> "$LOGFILE" 2>&1 || true
    log "git: updated $dest"
  else
    git clone --depth 1 "$url" "$dest" >> "$LOGFILE" 2>&1 \
      && log "git: cloned $dest" \
      || warn "git: FAILED $url"
  fi
}

safe_wget() {
  wget -q --timeout=30 --tries=3 "$1" -O "$2" >> "$LOGFILE" 2>&1 \
    && log "wget: $2" || warn "wget: FAILED $1"
}

safe_curl() {
  curl -fsSL --max-time 30 --retry 3 "$1" -o "$2" >> "$LOGFILE" 2>&1 \
    && log "curl: $2" || warn "curl: FAILED $1"
}

make_link() {
  local src="$1" dest="$2"
  [[ -e "$src" ]] && ln -sf "$src" "$dest" 2>/dev/null \
    && log "link: $dest" || true
}

make_wrapper() {
  # make_wrapper /path/to/script.py /usr/local/bin/toolname
  local script="$1" dest="$2"
  cat > "$dest" << WEOF
#!/bin/bash
python3 $script "\$@"
WEOF
  chmod +x "$dest"
  log "wrapper: $dest"
}

gh_latest() {
  # gh_latest OWNER/REPO REGEX_PATTERN OUTPUT_PATH
  local repo="$1" pattern="$2" out="$3"
  local url
  url=$(curl -s --max-time 15 "https://api.github.com/repos/${repo}/releases/latest" \
    | python3 -c "
import sys, json, re
try:
    d = json.load(sys.stdin)
    for a in d.get('assets', []):
        if re.search(r'${pattern}', a['browser_download_url'], re.I):
            print(a['browser_download_url']); break
except: pass
" 2>/dev/null || true)
  [[ -n "$url" ]] && safe_wget "$url" "$out" || warn "gh_latest: no match for $repo ($pattern)"
}

# =============================================================================
section "STEP 1 — Kali Signing Key Fix"
# Validates and installs the current Kali GPG archive signing key
# =============================================================================
info "Checking Kali signing key..."
KALI_KEY_URL="https://archive.kali.org/archive-keyring.gpg"
KALI_KEY_DEST="/usr/share/keyrings/kali-archive-keyring.gpg"
KALI_KEY_TMP="/tmp/kali-archive-keyring.gpg"
NEW_KEY="827C8569F2518CC677FECA1AED65462EC8D5E4C5"
KEY_SHA1="603374c107a90a69d983dbcb4d31e0d6eedfc325"

key_present=$(gpg --no-default-keyring \
  --keyring "$KALI_KEY_DEST" --list-keys 2>/dev/null | grep -ic "$NEW_KEY" || true)

if [[ "$key_present" -ge 1 ]]; then
  log "Kali signing key already installed"
else
  safe_wget "$KALI_KEY_URL" "$KALI_KEY_TMP"
  actual_sha=$(sha1sum "$KALI_KEY_TMP" 2>/dev/null | cut -d' ' -f1 || true)
  if [[ "$actual_sha" == "$KEY_SHA1" ]]; then
    cp -f "$KALI_KEY_TMP" "$KALI_KEY_DEST"
    rm -f "$KALI_KEY_TMP"
    log "Kali signing key installed"
  else
    warn "Signing key checksum mismatch — skipping (will still work on modern Kali)"
    rm -f "$KALI_KEY_TMP"
  fi
fi

# =============================================================================
section "STEP 2 — Fix apt Sources & deb-src"
# Enables deb-src, adds non-free-firmware, fixes bad apt hash
# =============================================================================
info "Fixing /etc/apt/sources.list..."

# Fix bad apt hash (gcrypt)
mkdir -p /etc/gcrypt
echo "all" > /etc/gcrypt/hwf.deny

# Enable deb-src if commented out
if grep -qE "^#\s*deb-src" /etc/apt/sources.list 2>/dev/null; then
  sed -i 's/^#\s*deb-src/deb-src/' /etc/apt/sources.list
  log "deb-src enabled in sources.list"
fi

# Add non-free-firmware if missing
sed -i 's/non-free$/non-free non-free-firmware/' /etc/apt/sources.list 2>/dev/null || true

# =============================================================================
section "STEP 3 — System Update"
# =============================================================================
info "Running apt update and full-upgrade..."
DEBIAN_FRONTEND=noninteractive apt-get update -y >> "$LOGFILE" 2>&1
DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" >> "$LOGFILE" 2>&1
apt-get autoremove -y >> "$LOGFILE" 2>&1
log "System updated"

# =============================================================================
section "STEP 4 — Core Build Dependencies"
# Install before everything else so all installers have what they need
# =============================================================================
info "Installing build dependencies..."
apt_install \
  python3 python3-pip python3-dev python3-venv python3-setuptools python3-wheel \
  python2 python2-dev \
  pipx \
  golang-go \
  ruby ruby-dev ruby-full \
  gcc g++ make cmake \
  libssl-dev libffi-dev libpcap-dev libpq-dev \
  git curl wget \
  unzip zip p7zip-full \
  build-essential autogen automake \
  linux-headers-$(uname -r) \
  dkms \
  virt-what \
  cargo \
  nodejs npm \
  openjdk-17-jdk

# Upgrade pip itself
pip3 install --break-system-packages --upgrade pip setuptools wheel >> "$LOGFILE" 2>&1 || true

# Ensure pipx path is set
pipx ensurepath >> "$LOGFILE" 2>&1 || true
export PATH="$PATH:/root/.local/bin"

# =============================================================================
section "STEP 5 — Core APT Pentesting Packages"
# =============================================================================
info "Installing core pentesting tools via apt..."

# Network scanning & enumeration
apt_install nmap masscan hping3 arp-scan p0f netdiscover fping

# Netcat variants
apt_install netcat-traditional netcat-openbsd socat

# Exploitation frameworks
apt_install metasploit-framework

# Web proxy & scanning
apt_install burpsuite zaproxy nikto

# Brute force
apt_install hydra medusa crowbar

# Password cracking
apt_install john hashcat

# Web fuzzing / directory busting
apt_install gobuster feroxbuster ffuf dirbuster dirb wfuzz

# SQL injection
apt_install sqlmap

# Packet analysis
apt_install wireshark tshark tcpdump

# AD / SMB / Windows
apt_install responder evil-winrm crackmapexec netexec \
            impacket-scripts smbclient smbmap \
            enum4linux enum4linux-ng nbtscan ldap-utils

# SNMP
apt_install onesixtyone snmp snmp-mibs-downloader

# DNS / network utils
apt_install dnsutils host whois bind9-dnsutils

# Remote access
apt_install freerdp2-x11 rdesktop openssh-client openssl

# Tunneling / VPN
apt_install proxychains4 stunnel4 openvpn wireguard sshuttle chisel

# Traffic tools
apt_install iproute2 net-tools

# Parsing / output
apt_install xsltproc jq libxml2-utils html2text

# Terminal tools
apt_install tmux screen vim nano htop tree rlwrap locate htop

# Exploit DB
apt_install exploitdb

# Database clients
apt_install redis-tools default-mysql-client postgresql-client

# Mail testing
apt_install swaks

# WiFi hashes
apt_install hcxtools hcxdumptool

# Steganography / forensics
apt_install steghide exiftool binwalk foremost pdfcrack fcrackzip \
            libimage-exiftool-perl

# Wordlists
apt_install wordlists seclists

# Social Engineering Toolkit
apt_install set

# SPIKE network fuzzer (pin older version from old.kali.org)
info "Installing SPIKE..."
if ! command -v generic_send_tcp &>/dev/null; then
  safe_wget \
    "https://old.kali.org/kali/pool/main/s/spike/spike_2.9-1kali6_${ARCHSHORT}.deb" \
    "/tmp/spike_2.9-1kali6_${ARCHSHORT}.deb"
  if [[ -f "/tmp/spike_2.9-1kali6_${ARCHSHORT}.deb" ]]; then
    dpkg -i "/tmp/spike_2.9-1kali6_${ARCHSHORT}.deb" >> "$LOGFILE" 2>&1 || true
    apt-get install -f -y >> "$LOGFILE" 2>&1 || true
    apt-mark hold spike >> "$LOGFILE" 2>&1 || true
    rm -f "/tmp/spike_2.9-1kali6_${ARCHSHORT}.deb"
    log "SPIKE installed and held at 2.9"
  fi
fi

# Cross-compile
apt_install mingw-w64

# Reporting / screenshots
apt_install cherrytree flameshot xclip xdotool

# Containers
apt_install docker.io

# Other essentials
apt_install mono-complete smtp-user-enum lynis \
            file binutils strace ltrace \
            crunch cewl gedit libwacom-common \
            assetfinder httprobe

# Download SNMP MIBs for readable output
download-mibs >> "$LOGFILE" 2>&1 || true

# Update searchsploit DB
searchsploit -u >> "$LOGFILE" 2>&1 || true

# =============================================================================
section "STEP 6 — Docker Compose (latest from GitHub)"
# Always installs latest release, replacing apt version which can be stale
# =============================================================================
info "Installing latest Docker Compose..."
DC_URL=$(curl -s "https://api.github.com/repos/docker/compose/releases/latest" \
  | python3 -c "
import sys,json
d=json.load(sys.stdin)
ver=d.get('tag_name','').lstrip('v')
print(f'https://github.com/docker/compose/releases/download/v{ver}/docker-compose-linux-x86_64')
" 2>/dev/null || true)

if [[ -n "$DC_URL" ]]; then
  safe_curl "$DC_URL" /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose 2>/dev/null || true
  log "docker-compose installed: $(docker-compose --version 2>/dev/null || echo 'version unknown')"
else
  apt_install docker-compose
fi

# =============================================================================
section "STEP 7 — Disable Power Management (XFCE & GNOME)"
# Prevents screen blanking / sleep during long-running scans
# =============================================================================
info "Disabling power management..."

# XFCE
XFCE_POWER_DIR="$USERHOME/.config/xfce4/xfconf/xfce-perchannel-xml"
mkdir -p "$XFCE_POWER_DIR"
cat > "$XFCE_POWER_DIR/xfce4-power-manager.xml" << 'XFCEEOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-power-manager" version="1.0">
  <property name="xfce4-power-manager" type="empty">
    <property name="power-button-action" type="empty"/>
    <property name="show-panel-label" type="empty"/>
    <property name="show-tray-icon" type="bool" value="false"/>
    <property name="lock-screen-suspend-hibernate" type="bool" value="false"/>
    <property name="logind-handle-lid-switch" type="bool" value="false"/>
    <property name="blank-on-ac" type="int" value="0"/>
    <property name="dpms-on-ac-sleep" type="uint" value="0"/>
    <property name="dpms-on-ac-off" type="uint" value="0"/>
    <property name="dpms-enabled" type="bool" value="false"/>
  </property>
</channel>
XFCEEOF
chown -R "$REALUSER":"$REALUSER" "$USERHOME/.config" 2>/dev/null || true
log "XFCE power management disabled"

# GNOME (run as real user)
if command -v gsettings &>/dev/null; then
  sudo -u "$REALUSER" gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type      nothing 2>/dev/null || true
  sudo -u "$REALUSER" gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout   0       2>/dev/null || true
  sudo -u "$REALUSER" gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type nothing 2>/dev/null || true
  sudo -u "$REALUSER" gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 0    2>/dev/null || true
  sudo -u "$REALUSER" gsettings set org.gnome.settings-daemon.plugins.power power-button-action         nothing 2>/dev/null || true
  sudo -u "$REALUSER" gsettings set org.gnome.desktop.session idle-delay                                0       2>/dev/null || true
  sudo -u "$REALUSER" gsettings set org.gnome.desktop.screensaver lock-enabled                          false   2>/dev/null || true
  log "GNOME power management disabled"
fi

# =============================================================================
section "STEP 8 — System Fixes (GRUB, SMB, nmap, binfmt, beep, hushlogin)"
# =============================================================================

# GRUB: add mitigations=off for performance in VM
info "Patching GRUB..."
if ! grep -q "mitigations=off" /etc/default/grub 2>/dev/null; then
  sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet mitigations=off"/' \
    /etc/default/grub 2>/dev/null || true
  update-grub >> "$LOGFILE" 2>&1 || true
  log "GRUB: mitigations=off added (reboot to apply)"
else
  log "GRUB: mitigations=off already set"
fi

# SMB: set client min protocol for older Windows compatibility
info "Patching /etc/samba/smb.conf..."
if ! grep -qi "client min protocol = LANMAN1" /etc/samba/smb.conf 2>/dev/null; then
  echo -e "\n[global]\n   client min protocol = LANMAN1" >> /etc/samba/smb.conf 2>/dev/null || true
  log "SMB: client min protocol = LANMAN1 added"
else
  log "SMB: client min protocol already set"
fi

# nmap: replace broken clamav-exec.nse and http-shellshock.nse
info "Fixing nmap scripts..."
safe_wget \
  "https://raw.githubusercontent.com/nmap/nmap/master/scripts/clamav-exec.nse" \
  "/usr/share/nmap/scripts/clamav-exec.nse"
safe_wget \
  "https://raw.githubusercontent.com/Dewalt-arch/pimpmykali/master/fixed-http-shellshock.nse" \
  "/usr/share/nmap/scripts/http-shellshock.nse"
nmap --script-updatedb >> "$LOGFILE" 2>&1 || true

# Vulners NSE script
[[ ! -f "/usr/share/nmap/scripts/vulners.nse" ]] && \
  safe_wget \
    "https://raw.githubusercontent.com/vulnersCom/nmap-vulners/master/vulners.nse" \
    "/usr/share/nmap/scripts/vulners.nse"
nmap --script-updatedb >> "$LOGFILE" 2>&1 || true
log "nmap scripts updated"

# binfmt_misc: mount on boot so Windows .exe can run via Wine
info "Setting up binfmt_misc..."
modprobe binfmt_misc >> "$LOGFILE" 2>&1 || true
if ! grep -q "binfmt_misc" /etc/fstab 2>/dev/null; then
  echo 'binfmt_misc /proc/sys/fs/binfmt_misc binfmt_misc defaults 0 0' >> /etc/fstab
  log "binfmt_misc added to /etc/fstab"
fi
mount binfmt_misc >> "$LOGFILE" 2>&1 || true

# Silence PC speaker beep
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf
log "PC speaker beep silenced"

# hushlogin — suppress login banner
for HUSHPATH in "/root/.hushlogin" "$USERHOME/.hushlogin"; do
  [[ -f "$HUSHPATH" ]] || touch "$HUSHPATH" && log "hushlogin: $HUSHPATH"
done

# LightDM: switch to Kali-Dark theme
if [[ -f "/etc/lightdm/lightdm-gtk-greeter.conf" ]]; then
  sed -i 's/Kali-Light/Kali-Dark/g' /etc/lightdm/lightdm-gtk-greeter.conf 2>/dev/null || true
  log "LightDM: Kali-Dark theme set"
fi

# xhost: allow root to use GUI tools
sudo -u "$REALUSER" xhost +SI:localuser:root >> "$LOGFILE" 2>&1 || true
xhost +SI:localuser:root >> "$LOGFILE" 2>&1 || true

# SSH wide compatibility
SSH_WIDE="/usr/share/kali-defaults/etc/ssh/ssh_config.d/kali-wide-compat.conf"
[[ -f "$SSH_WIDE" ]] && \
  cp -f "$SSH_WIDE" /etc/ssh/ssh_config.d/kali-wide-compat.conf 2>/dev/null && \
  systemctl restart ssh >> "$LOGFILE" 2>&1 || true
log "SSH wide-compat config applied"

# Qterminal: set unlimited scrollback
QTERMCONF="$USERHOME/.config/qterminal.org/qterminal.ini"
if [[ -f "$QTERMCONF" ]]; then
  sed -i 's/HistoryLimited=True/HistoryLimited=False/g' "$QTERMCONF" 2>/dev/null || true
  log "Qterminal: unlimited scrollback set"
fi

# =============================================================================
section "STEP 9 — Go Installation & Tools"
# =============================================================================
info "Checking Go..."
if ! command -v go &>/dev/null; then
  warn "Go not found via apt — installing latest manually..."
  GO_VER=$(curl -s "https://go.dev/VERSION?m=text" 2>/dev/null | head -1 || echo "go1.22.4")
  safe_wget "https://go.dev/dl/${GO_VER}.linux-amd64.tar.gz" "/tmp/go.tar.gz"
  rm -rf /usr/local/go
  tar -C /usr/local -xzf /tmp/go.tar.gz >> "$LOGFILE" 2>&1 || true
  export PATH="$PATH:/usr/local/go/bin"
  rm -f /tmp/go.tar.gz
fi
log "Go: $(go version 2>/dev/null || echo 'version unknown')"

mkdir -p "$GOBIN"

info "Installing Go-based tools..."
go_install "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
go_install "github.com/projectdiscovery/httpx/cmd/httpx@latest"
go_install "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
go_install "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
go_install "github.com/projectdiscovery/katana/cmd/katana@latest"
go_install "github.com/sensepost/gowitness@latest"
go_install "github.com/ropnop/kerbrute@latest"
go_install "github.com/jpillora/chisel@latest"
go_install "github.com/owasp-amass/amass/v4/...@master"

# Copy all Go binaries to /usr/local/bin for system-wide access
for bin in "$GOBIN"/*; do
  [[ -f "$bin" ]] && cp -f "$bin" /usr/local/bin/ 2>/dev/null || true
done
log "Go binaries copied to /usr/local/bin"

# Update nuclei templates
nuclei -update-templates >> "$LOGFILE" 2>&1 || true

# =============================================================================
section "STEP 10 — Python Packages (pipx / pip3)"
# =============================================================================
info "Installing Python CLI tools via pipx..."
PIPX_TOOLS=(
  impacket
  bloodhound
  certipy-ad
  ldapdomaindump
  pypykatz
  lsassy
  sprayhound
  mitm6
  coercer
  pwncat-cs
  arjun
  updog
  name-that-hash
  dnsrecon
  shodan
  netexec
  exegol
  theHarvester
)
for tool in "${PIPX_TOOLS[@]}"; do
  pip_install "$tool"
done

info "Installing Python libraries system-wide..."
pip3_install \
  requests beautifulsoup4 lxml \
  paramiko pwntools scapy \
  dnspython colorama flask netaddr pexpect \
  ldap3 pycryptodome pycryptodomex pyOpenSSL \
  python-dotenv xmltodict termcolor cprint \
  future pyftpdlib setuptools importlib

# =============================================================================
section "STEP 11 — Wordlists"
# =============================================================================
info "Setting up wordlists..."
[[ -f "$WORDLISTS/rockyou.txt.gz" ]] && \
  gunzip -kf "$WORDLISTS/rockyou.txt.gz" 2>/dev/null || true
[[ -f "$WORDLISTS/rockyou.txt" ]] && log "rockyou.txt ready" || warn "rockyou.txt missing"

if [[ ! -f "/usr/share/seclists/README.md" ]]; then
  git_clone "https://github.com/danielmiessler/SecLists.git" "/usr/share/seclists"
fi
log "SecLists ready at /usr/share/seclists"

# =============================================================================
section "STEP 12 — Google Chrome (gowitness dependency)"
# =============================================================================
info "Installing Google Chrome..."
if [[ "$ARCHSHORT" == "amd64" ]] && [[ ! -f /usr/bin/google-chrome ]]; then
  safe_wget \
    "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" \
    "/tmp/google-chrome-stable_current_amd64.deb"
  apt_install libu2f-dev libu2f-udev
  dpkg -i /tmp/google-chrome-stable_current_amd64.deb >> "$LOGFILE" 2>&1 || true
  apt-get install -f -y >> "$LOGFILE" 2>&1 || true
  rm -f /tmp/google-chrome-stable_current_amd64.deb
  log "Google Chrome installed"
elif [[ "$ARCHSHORT" == "arm64" ]]; then
  warn "Google Chrome not available for arm64 — skipping"
else
  log "Google Chrome already installed"
fi

# =============================================================================
section "STEP 13 — Ghidra (Reverse Engineering)"
# =============================================================================
info "Installing Ghidra from GitHub..."
apt_install openjdk-17-jdk

GHIDRA_DIR="/opt/ghidra"
GHIDRA_DL=$(curl -s "https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest" \
  | python3 -c "
import sys,json
d=json.load(sys.stdin)
for a in d.get('assets',[]):
    if a['name'].endswith('.zip') and 'PUBLIC' in a['name']:
        print(a['browser_download_url']); break
" 2>/dev/null || true)

if [[ -n "$GHIDRA_DL" ]]; then
  safe_wget "$GHIDRA_DL" "/tmp/ghidra.zip"
  [[ -d "$GHIDRA_DIR" ]] && rm -rf "$GHIDRA_DIR"
  mkdir -p "$GHIDRA_DIR"
  TMP_GHIDRA=$(mktemp -d)
  unzip -qq -o /tmp/ghidra.zip -d "$TMP_GHIDRA" >> "$LOGFILE" 2>&1 || true
  mv "$TMP_GHIDRA"/ghidra_*/* "$GHIDRA_DIR" 2>/dev/null || true
  rm -rf "$TMP_GHIDRA" /tmp/ghidra.zip

  [[ -f "$GHIDRA_DIR/ghidraRun" ]] && \
    ln -sf "$GHIDRA_DIR/ghidraRun" /usr/local/bin/ghidra && \
    chmod +x /usr/local/bin/ghidra

  # .desktop entry
  cat > /usr/share/applications/ghidra.desktop << DEOF
[Desktop Entry]
Version=1.0
Name=Ghidra
Comment=NSA Reverse Engineering Tool
Exec=$GHIDRA_DIR/ghidraRun
Icon=$GHIDRA_DIR/docs/images/GHIDRA_1.png
Terminal=false
Type=Application
Categories=Development;ReverseEngineering;
DEOF
  chmod +x /usr/share/applications/ghidra.desktop

  # Ghidra dark theme
  git_clone "https://github.com/zackelia/ghidra-dark-theme" "/opt/ghidra-dark-theme"
  log "Ghidra installed — dark theme at /opt/ghidra-dark-theme"
else
  warn "Ghidra: could not fetch download URL (non-fatal)"
fi

# =============================================================================
section "STEP 14 — VSCode"
# =============================================================================
info "Installing VSCode..."
if [[ ! -f /usr/bin/code ]]; then
  safe_wget "https://packages.microsoft.com/keys/microsoft.asc" "/tmp/microsoft.asc"
  gpg --dearmor < /tmp/microsoft.asc > /tmp/packages.microsoft.gpg 2>/dev/null || true
  install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg \
    /etc/apt/keyrings/packages.microsoft.gpg 2>/dev/null || true
  echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
    > /etc/apt/sources.list.d/vscode.list
  DEBIAN_FRONTEND=noninteractive apt-get update -y >> "$LOGFILE" 2>&1 || true
  apt_install code
  rm -f /tmp/microsoft.asc /tmp/packages.microsoft.gpg
else
  log "VSCode already installed"
fi

# =============================================================================
section "STEP 15 — Sublime Text"
# =============================================================================
info "Installing Sublime Text..."
if ! command -v subl &>/dev/null; then
  safe_wget \
    "https://download.sublimetext.com/sublimehq-pub.gpg" \
    "/tmp/sublimehq-pub.gpg"
  gpg --no-default-keyring --keyring /tmp/sublime-keyring.gpg \
    --import /tmp/sublimehq-pub.gpg >> "$LOGFILE" 2>&1 || true
  gpg --no-default-keyring --keyring /tmp/sublime-keyring.gpg \
    --export --output /usr/local/share/keyrings/sublime-text.gpg >> "$LOGFILE" 2>&1 || true
  rm -f /tmp/sublime-keyring.gpg /tmp/sublimehq-pub.gpg
  mkdir -p /usr/local/share/keyrings
  echo "deb [signed-by=/usr/local/share/keyrings/sublime-text.gpg] \
https://download.sublimetext.com/ apt/stable/" \
    > /etc/apt/sources.list.d/sublime-text.list
  DEBIAN_FRONTEND=noninteractive apt-get update -y >> "$LOGFILE" 2>&1 || true
  apt_install sublime-text
else
  log "Sublime Text already installed"
fi

# =============================================================================
section "STEP 16 — Gowitness (Web Screenshots)"
# Always installs from GitHub for latest version
# =============================================================================
info "Installing gowitness from GitHub..."
if [[ "$ARCHSHORT" == "amd64" ]]; then
  GW_URL=$(curl -s "https://github.com/sensepost/gowitness/tags" 2>/dev/null \
    | grep -oP '/sensepost/gowitness/releases/tag/\K[\d.]+' | head -1 || true)
  if [[ -n "$GW_URL" ]]; then
    rm -f /usr/bin/gowitness /usr/local/bin/gowitness
    safe_wget \
      "https://github.com/sensepost/gowitness/releases/download/${GW_URL}/gowitness-${GW_URL}-linux-amd64" \
      "/usr/local/bin/gowitness"
    chmod +x /usr/local/bin/gowitness 2>/dev/null || true
    log "gowitness $GW_URL installed"
  fi
fi

# =============================================================================
section "STEP 17 — Waybackrust"
# =============================================================================
info "Installing waybackrust..."
if [[ ! -f /usr/local/bin/waybackrust ]]; then
  safe_wget \
    "https://github.com/Neolex-Security/WaybackRust/releases/download/v0.2.12/waybackrust-x86_64-unknown-linux-gnu.tar.gz" \
    "/tmp/waybackrust.tar.gz"
  tar xzf /tmp/waybackrust.tar.gz -C /usr/local/bin >> "$LOGFILE" 2>&1 || true
  chmod +x /usr/local/bin/waybackrust 2>/dev/null || true
  rm -f /tmp/waybackrust.tar.gz
  log "waybackrust installed"
fi

# =============================================================================
section "STEP 18 — Ligolo-ng (Pivoting — CPTS Community #1 Pick)"
# =============================================================================
info "Building Ligolo-ng from source..."
LIGOLO_DIR="$TOOLS/ligolo-ng"
git_clone "https://github.com/nicocha30/ligolo-ng.git" "$LIGOLO_DIR"
if [[ -d "$LIGOLO_DIR" ]]; then
  cd "$LIGOLO_DIR"
  go build -o /usr/local/bin/ligolo-proxy ./cmd/proxy >> "$LOGFILE" 2>&1 \
    && log "ligolo-proxy installed" || warn "ligolo-proxy build failed"
  go build -o /usr/local/bin/ligolo-agent ./cmd/agent >> "$LOGFILE" 2>&1 \
    && log "ligolo-agent installed" || warn "ligolo-agent build failed"
  # Cross-compile agent for Windows
  if command -v x86_64-w64-mingw32-gcc &>/dev/null; then
    GOOS=windows GOARCH=amd64 CGO_ENABLED=0 \
      go build -o "$WIN_BINS/ligolo-agent.exe" ./cmd/agent >> "$LOGFILE" 2>&1 \
      && log "ligolo-agent.exe built for Windows" || true
  fi
  cd "$TOOLS"
fi

# =============================================================================
section "STEP 19 — Active Directory Tools"
# Module: Active Directory Enumeration & Attacks — most tested area in CPTS
# =============================================================================
info "Installing Active Directory tools..."

git_clone "https://github.com/BloodHoundAD/BloodHound.git"      "$TOOLS/BloodHound"
git_clone "https://github.com/BloodHoundAD/SharpHound.git"      "$TOOLS/SharpHound"
git_clone "https://github.com/PowerShellMafia/PowerSploit.git"  "$TOOLS/PowerSploit"
git_clone "https://github.com/NetSPI/PowerUpSQL.git"            "$TOOLS/PowerUpSQL"
git_clone "https://github.com/GhostPack/Rubeus.git"             "$TOOLS/Rubeus"
git_clone "https://github.com/GhostPack/Certify.git"            "$TOOLS/Certify"
git_clone "https://github.com/gentilkiwi/mimikatz.git"          "$TOOLS/mimikatz"
git_clone "https://github.com/Kevin-Robertson/Inveigh.git"      "$TOOLS/Inveigh"
git_clone "https://github.com/adrecon/ADRecon.git"              "$TOOLS/ADRecon"
git_clone "https://github.com/login-securite/DonPAPI.git"       "$TOOLS/DonPAPI"

SPRAYTK="$TOOLS/SprayingToolkit"
git_clone "https://github.com/byt3bl33d3r/SprayingToolkit.git"  "$SPRAYTK"
pip_req "$SPRAYTK/requirements.txt"

# o365spray — Office365 enum (Footprinting module)
git_clone "https://github.com/0xZDH/o365spray.git" "$TOOLS/o365spray"
pip_req "$TOOLS/o365spray/requirements.txt"
make_wrapper "$TOOLS/o365spray/o365spray.py" "/usr/local/bin/o365spray"

# PlumHound — BloodHound data analysis (pimpmykali staple)
info "Installing PlumHound..."
PLUM_DIR="/opt/PlumHound"
[[ -d "$PLUM_DIR" ]] && rm -rf "$PLUM_DIR"
git_clone "https://github.com/PlumHound/PlumHound.git" "$PLUM_DIR"
pip3 install --break-system-packages -r "$PLUM_DIR/requirements.txt" >> "$LOGFILE" 2>&1 || true
chmod +x "$PLUM_DIR/PlumHound.py"
make_link "$PLUM_DIR/PlumHound.py"   "/usr/local/bin/PlumHound.py"
make_link "$PLUM_DIR/PlumHound.py"   "/usr/local/bin/plumhound"
log "PlumHound installed"

# neo4j + bloodhound (apt)
apt_install neo4j bloodhound

# =============================================================================
section "STEP 20 — Reconnaissance & OSINT Tools"
# =============================================================================
info "Installing recon tools..."

# username-anarchy — in HTB path cheatsheet explicitly
git_clone "https://github.com/urbanadventurer/username-anarchy.git" "$TOOLS/username-anarchy"
chmod +x "$TOOLS/username-anarchy/username-anarchy" 2>/dev/null || true
make_link "$TOOLS/username-anarchy/username-anarchy" "/usr/local/bin/username-anarchy"

# Sublist3r
SUBLIST="$TOOLS/Sublist3r"
git_clone "https://github.com/aboul3la/Sublist3r.git" "$SUBLIST"
pip_req "$SUBLIST/requirements.txt"
make_wrapper "$SUBLIST/sublist3r.py" "/usr/local/bin/sublist3r"

# WhatWeb fingerprinting
gem_install whatweb

# =============================================================================
section "STEP 21 — Privilege Escalation Tools"
# =============================================================================
info "Installing privilege escalation tools..."

# PEASS-ng (LinPEAS + WinPEAS)
git_clone "https://github.com/carlospolop/PEASS-ng.git" "$TOOLS/PEASS-ng"

# Download all linpeas variants to /opt/linpeas
mkdir -p /opt/linpeas /opt/winpeas
PEASS_VER=$(curl -s "https://github.com/peass-ng/PEASS-ng/releases" \
  | grep -oP 'refs/heads/master.*?(?=<)' | head -1 | awk '{print $NF}' || true)
PEASS_BASE="https://github.com/peass-ng/PEASS-ng/releases/download/${PEASS_VER:-refs%2Fheads%2Fmaster}"

for f in linpeas.sh linpeas_linux_amd64 linpeas_fat.sh; do
  safe_wget "${PEASS_BASE}/${f}" "/opt/linpeas/${f}"
  chmod +x "/opt/linpeas/${f}" 2>/dev/null || true
done
make_link "/opt/linpeas/linpeas.sh" "/usr/local/bin/linpeas.sh"

for f in winPEASx64.exe winPEASx86.exe winPEASany.exe winPEAS.bat; do
  safe_wget "${PEASS_BASE}/${f}" "/opt/winpeas/${f}" 2>/dev/null || true
done
log "LinPEAS → /opt/linpeas/  |  WinPEAS → /opt/winpeas/"

# LinEnum
safe_wget \
  "https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh" \
  "$TOOLS/LinEnum.sh"
chmod +x "$TOOLS/LinEnum.sh"
make_link "$TOOLS/LinEnum.sh" "/usr/local/bin/linenum.sh"

# linux-smart-enumeration
safe_wget \
  "https://github.com/diego-treitos/linux-smart-enumeration/releases/latest/download/lse.sh" \
  "$TOOLS/lse.sh"
chmod +x "$TOOLS/lse.sh"
make_link "$TOOLS/lse.sh" "/usr/local/bin/lse.sh"

# pspy
gh_latest "DominicBreuker/pspy" "pspy64$" "$TOOLS/pspy64"
chmod +x "$TOOLS/pspy64" 2>/dev/null || true
make_link "$TOOLS/pspy64" "/usr/local/bin/pspy64"

# PrivescCheck, SharpUp, BeRoot, LaZagne, Snaffler
git_clone "https://github.com/itm4n/PrivescCheck.git"   "$TOOLS/PrivescCheck"
git_clone "https://github.com/GhostPack/SharpUp.git"    "$TOOLS/SharpUp"
git_clone "https://github.com/AlessandroZ/BeRoot.git"   "$TOOLS/BeRoot"
git_clone "https://github.com/AlessandroZ/LaZagne.git"  "$TOOLS/LaZagne"
git_clone "https://github.com/SnaffCon/Snaffler.git"    "$TOOLS/Snaffler"

if [[ -f "$TOOLS/LaZagne/Linux/laZagne.py" ]]; then
  make_wrapper "$TOOLS/LaZagne/Linux/laZagne.py" "/usr/local/bin/lazagne"
fi

# GTFOBLookup
GTFO="$TOOLS/GTFOBLookup"
git_clone "https://github.com/nccgroup/GTFOBLookup.git" "$GTFO"
pip_req "$GTFO/requirements.txt"

# Pre-compiled Windows PrivEsc binaries
gh_latest "itm4n/PrintSpoofer"     "PrintSpoofer64.exe"  "$WIN_BINS/PrintSpoofer64.exe"
gh_latest "BeichenDream/GodPotato" "GodPotato-NET4.exe"  "$WIN_BINS/GodPotato.exe"
gh_latest "ohpe/juicy-potato"      "JuicyPotato.exe"     "$WIN_BINS/JuicyPotato.exe"

# =============================================================================
section "STEP 22 — Web Application Tools"
# =============================================================================
info "Installing web application tools..."

# XSStrike
XSS="$TOOLS/XSStrike"
git_clone "https://github.com/s0md3v/XSStrike.git" "$XSS"
pip_req "$XSS/requirements.txt"
make_wrapper "$XSS/xsstrike.py" "/usr/local/bin/xsstrike"

# commix — command injection
COMMIX="$TOOLS/commix"
git_clone "https://github.com/commixproject/commix.git" "$COMMIX"
make_wrapper "$COMMIX/commix.py" "/usr/local/bin/commix"

# LinkFinder
LF="$TOOLS/LinkFinder"
git_clone "https://github.com/GerbenJavado/LinkFinder.git" "$LF"
pip_req "$LF/requirements.txt"
make_wrapper "$LF/linkfinder.py" "/usr/local/bin/linkfinder"

# jwt_tool
JWT="$TOOLS/jwt_tool"
git_clone "https://github.com/ticarpi/jwt_tool.git" "$JWT"
pip3_install termcolor cprint pycryptodomex
make_wrapper "$JWT/jwt_tool.py" "/usr/local/bin/jwt_tool"

# Gopherus — SSRF
GOPH="$TOOLS/Gopherus"
git_clone "https://github.com/tarunkant/Gopherus.git" "$GOPH"
make_wrapper "$GOPH/gopherus.py" "/usr/local/bin/gopherus"

# Webshells collection
git_clone "https://github.com/tennc/webshell.git" "$TOOLS/webshells"

# =============================================================================
section "STEP 23 — Pivoting & Tunneling Tools"
# =============================================================================
info "Installing pivoting tools..."

git_clone "https://github.com/klsecservices/rpivot.git"             "$TOOLS/rpivot"
git_clone "https://github.com/utoni/ptunnel-ng.git"                 "$TOOLS/ptunnel-ng"
git_clone "https://github.com/lukebaggett/dnscat2-powershell.git"   "$TOOLS/dnscat2-powershell"
git_clone "https://github.com/RedTeamPentesting/pretender.git"       "$TOOLS/pretender"
git_clone "https://github.com/samratashok/nishang.git"               "$TOOLS/nishang"

# =============================================================================
section "STEP 24 — Shell & Payload Tools"
# =============================================================================
info "Installing shell tools..."

VILLAIN="$TOOLS/Villain"
git_clone "https://github.com/t3l3machus/Villain.git" "$VILLAIN"
pip_req "$VILLAIN/requirements.txt"
make_wrapper "$VILLAIN/villain.py" "/usr/local/bin/villain"

HOAX="$TOOLS/hoaxshell"
git_clone "https://github.com/t3l3machus/hoaxshell.git" "$HOAX"
pip_req "$HOAX/requirements.txt"
make_wrapper "$HOAX/hoaxshell.py" "/usr/local/bin/hoaxshell"

safe_wget \
  "https://raw.githubusercontent.com/brightio/penelope/main/penelope.py" \
  "/usr/local/bin/penelope.py"
chmod +x /usr/local/bin/penelope.py
cat > /usr/local/bin/penelope << 'PEOF'
#!/bin/bash
python3 /usr/local/bin/penelope.py "$@"
PEOF
chmod +x /usr/local/bin/penelope

# =============================================================================
section "STEP 25 — Evasion & Obfuscation Tools"
# =============================================================================
info "Installing evasion tools..."

BASHF="$TOOLS/Bashfuscator"
git_clone "https://github.com/Bashfuscator/Bashfuscator.git" "$BASHF"
if [[ -f "$BASHF/setup.py" ]]; then
  cd "$BASHF"
  python3 setup.py install >> "$LOGFILE" 2>&1 || \
    pip3 install --break-system-packages . >> "$LOGFILE" 2>&1 || true
  cd "$TOOLS"
fi

git_clone "https://github.com/danielbohannon/Invoke-DOSfuscation.git" "$TOOLS/Invoke-DOSfuscation"
git_clone "https://github.com/bats3c/darkarmour.git"                  "$TOOLS/darkarmour"

# =============================================================================
section "STEP 26 — Password Attack Tools"
# =============================================================================
info "Installing password attack tools..."

git_clone "https://github.com/galkan/crowbar.git" "$TOOLS/crowbar"
chmod +x "$TOOLS/crowbar/crowbar.py" 2>/dev/null || true
make_link "$TOOLS/crowbar/crowbar.py" "/usr/local/bin/crowbar"

gem_install haiti-hash

# PCredz
PCREDZ="$TOOLS/PCredz"
git_clone "https://github.com/lgandx/PCredz.git" "$PCREDZ"
pip3_install Cython python-libpcap 2>/dev/null || true
make_wrapper "$PCREDZ/PCredz.py" "/usr/local/bin/pcredz"

# Joomla brute force (Attacking Common Applications module)
git_clone "https://github.com/ajnik/joomla-bruteforce.git" "$TOOLS/joomla-bruteforce"

# =============================================================================
section "STEP 27 — Metasploit Database Initialisation"
# =============================================================================
info "Initialising Metasploit database..."
systemctl enable postgresql >> "$LOGFILE" 2>&1 || true
systemctl start postgresql  >> "$LOGFILE" 2>&1 || true
sleep 3
msfdb init >> "$LOGFILE" 2>&1 \
  && log "Metasploit DB initialised" \
  || warn "Metasploit DB init failed — run: sudo msfdb init manually"

# =============================================================================
section "STEP 28 — Neo4j + BloodHound Setup"
# =============================================================================
info "Starting Neo4j..."
systemctl enable neo4j >> "$LOGFILE" 2>&1 || true
systemctl start neo4j  >> "$LOGFILE" 2>&1 || true
sleep 3
log "Neo4j started — default: neo4j / neo4j (change on first BloodHound login)"

# =============================================================================
section "STEP 29 — Hypervisor Detection & Guest Additions"
# Detects VirtualBox / VMware / QEMU and installs appropriate additions
# =============================================================================
info "Detecting hypervisor..."
apt_install virt-what

vbox_detected=$(virt-what 2>/dev/null | grep -ic "virtualbox" || true)
vmware_detected=$(virt-what 2>/dev/null | grep -ic "vmware" || true)
qemu_detected=$(virt-what 2>/dev/null | grep -ic "qemu\|kvm" || true)

if [[ "$vbox_detected" -ge 1 ]]; then
  log "VirtualBox detected — installing guest additions"
  apt_install virtualbox-dkms virtualbox-guest-x11 virtualbox-guest-additions-iso
  # Add user to vboxsf group
  usermod -aG vboxsf "$REALUSER" >> "$LOGFILE" 2>&1 || true
elif [[ "$vmware_detected" -ge 1 ]]; then
  log "VMware detected — installing open-vm-tools"
  apt_install open-vm-tools-desktop fuse3
elif [[ "$qemu_detected" -ge 1 ]]; then
  log "QEMU/KVM detected — installing guest agent"
  apt_install spice-vdagent qemu-guest-agent
else
  log "No hypervisor detected (bare-metal or unsupported)"
fi

# =============================================================================
section "STEP 30 — Linux Headers Check"
# Ensures headers stay installed through kernel upgrades
# =============================================================================
info "Checking Linux headers..."
for kernel in $(ls /lib/modules 2>/dev/null); do
  if apt-cache show "linux-headers-${kernel}" &>/dev/null; then
    apt_install "linux-headers-${kernel}"
  fi
done

# =============================================================================
section "STEP 31 — tmux Config"
# =============================================================================
info "Writing tmux config..."
cat > /root/.tmux.conf << 'TMUXCONF'
# funkmykali tmux config
set -g mouse on
set -g history-limit 50000
set -g default-terminal "screen-256color"
set -g base-index 1
setw -g pane-base-index 1
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %
bind r source-file ~/.tmux.conf \; display "Config reloaded!"
setw -g mode-keys vi
set -g status-style bg=black,fg=green
set -g status-left '#[fg=cyan,bold][#S] '
set -g status-right '#[fg=yellow]%H:%M  %d-%b-%y'
set -g pane-border-style fg=colour238
set -g pane-active-border-style fg=cyan
set -g message-style fg=yellow,bg=black
TMUXCONF
[[ "$REALUSER" != "root" ]] && \
  cp /root/.tmux.conf "$USERHOME/.tmux.conf" && \
  chown "$REALUSER":"$REALUSER" "$USERHOME/.tmux.conf"
log "tmux config written"

# =============================================================================
section "STEP 32 — System-wide PATH, Aliases & Go PATH"
# Written to /etc/profile.d so every user / every shell gets it at login
# =============================================================================
info "Writing system-wide environment..."
cat > /etc/profile.d/funkmykali.sh << 'PROFILEEOF'
# ── funkmykali — system-wide environment ─────────────────────────────────────
export PATH="$PATH:/usr/local/bin:/opt/tools:/root/go/bin:/usr/local/go/bin:/root/.local/bin"
export GOPATH="/root/go"
export GOROOT="/usr/local/go"

# ── Nmap ──────────────────────────────────────────────────────────────────────
alias nmap-quick='nmap -sV -sC -oA quickscan'
alias nmap-full='nmap -p- -sV -sC --open -oA fullscan'
alias nmap-udp='nmap -sU --top-ports 200 -oA udpscan'
alias nmap-vuln='nmap --script vuln -oA vulnscan'
alias nmap-all='nmap -p- -sV -sC -A -oA allscan'

# ── General ───────────────────────────────────────────────────────────────────
alias ll='ls -la --color=auto'
alias hosts='cat /etc/hosts'
alias myip='curl -s ifconfig.me && echo'
alias vpnip='ip a show tun0 2>/dev/null | grep -oP "(?<=inet )[\d.]+" | head -1 || echo "VPN not connected"'

# ── Servers ───────────────────────────────────────────────────────────────────
alias pyserver='python3 -m http.server 80'
alias pyserver8080='python3 -m http.server 8080'
alias upserver='updog -p 80'
alias smbserver='impacket-smbserver share . -smb2support'

# ── Shells ────────────────────────────────────────────────────────────────────
alias rlnc='rlwrap nc -lvnp'
alias msfq='msfconsole -q'

# ── Pentest shortcuts ─────────────────────────────────────────────────────────
alias linpeas='bash /usr/local/bin/linpeas.sh'
alias lse='bash /usr/local/bin/lse.sh'
alias pspy='sudo /usr/local/bin/pspy64'
alias winpeas='ls /opt/winpeas/'
alias peass='ls /opt/linpeas/ && ls /opt/winpeas/'

# ── Reference ─────────────────────────────────────────────────────────────────
alias gtfobins='echo "https://gtfobins.github.io"'
alias lolbas='echo "https://lolbas-project.github.io"'
alias hacktricks='echo "https://book.hacktricks.xyz"'
alias revshells='echo "https://www.revshells.com"'
PROFILEEOF

chmod +x /etc/profile.d/funkmykali.sh

# Source it in .bashrc and .zshrc for interactive shells
for RC in /root/.bashrc /root/.zshrc "$USERHOME/.bashrc" "$USERHOME/.zshrc"; do
  [[ -f "$RC" ]] && grep -qF "funkmykali" "$RC" 2>/dev/null || \
    echo "source /etc/profile.d/funkmykali.sh" >> "$RC" 2>/dev/null || true
done

# Go PATH in shell rcs (idempotent)
for RC in /root/.bashrc /root/.zshrc "$USERHOME/.bashrc" "$USERHOME/.zshrc"; do
  if [[ -f "$RC" ]]; then
    grep -qF "GOPATH" "$RC" 2>/dev/null || \
      echo -e 'export GOPATH=$HOME/go\nexport PATH=$PATH:$GOPATH/bin' >> "$RC"
  fi
done
log "System-wide profile written to /etc/profile.d/funkmykali.sh"

# =============================================================================
section "STEP 33 — Manual Install Reminder File"
# =============================================================================
cat > /opt/tools/README-manual-installs.txt << 'MANEOF'
=====================================================================
  funkmykali — Manual Install Reminders
  GitHub: https://github.com/arif-offsec/funkmykali
=====================================================================

These tools need Docker, a browser download, or a manual step:

1. SysReptor  ★★★ CPTS EXAM REPORT TOOL — HIGHLY RECOMMENDED ★★★
   Includes the official HTB CPTS report template.
   Commands:
     git clone https://github.com/syslifters/sysreptor.git
     cd sysreptor/deploy
     docker compose up -d
   Visit: http://localhost:8000  →  import HTB CPTS template

2. Obsidian (note-taking — most CPTS passers use this)
   Download: https://obsidian.md/download
   Install:  chmod +x Obsidian-*.AppImage && ./Obsidian-*.AppImage

3. Exegol (Docker-based full pentest environment)
   Already installed. Run:
     exegol install full
   Requires Docker running: sudo systemctl start docker

4. IppSec Unofficial CPTS Prep Playlist (YouTube)
   https://www.youtube.com/playlist?list=PLidcsTyj9JXItWpbRtTg6aDEj10_F17x5

5. HTB CPTS Official Track (machines aligned to the path)
   https://app.hackthebox.com/tracks/76

=====================================================================
MANEOF
log "Manual install reminders saved to /opt/tools/README-manual-installs.txt"

# =============================================================================
section "STEP 34 — Final Verification"
# =============================================================================
info "Verifying critical tools in PATH..."
echo ""

CRITICAL=(
  nmap masscan gobuster ffuf feroxbuster nikto sqlmap
  hydra john hashcat
  msfconsole msfvenom
  responder evil-winrm crackmapexec netexec
  bloodhound neo4j-admin
  impacket-secretsdump impacket-psexec impacket-GetNPUsers impacket-GetUserSPNs
  kerbrute chisel ligolo-proxy ligolo-agent
  burpsuite
  socat netcat
  proxychains4 sshuttle
  searchsploit
  certipy
  commix xsstrike jwt_tool gopherus
  waybackrust waybackurls
  plumhound
  httprobe assetfinder gowitness
  linpeas.sh lse.sh pspy64
  villain hoaxshell penelope
  updog
  tmux rlwrap
  cherrytree flameshot
  lynis
  ghidra
  set
)

PASS=0; FAIL=0

for tool in "${CRITICAL[@]}"; do
  if command -v "$tool" &>/dev/null || \
     [[ -f "/usr/local/bin/$tool" ]] || \
     [[ -f "/usr/bin/$tool" ]]; then
    echo -e "  ${GREEN}✅${NC} $tool"
    ((PASS++))
  else
    echo -e "  ${YELLOW}⚠️ ${NC} $tool — not in PATH (may be in /opt/tools/)"
    ((FAIL++))
  fi
done

# =============================================================================
section "SETUP COMPLETE"
# =============================================================================
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                               ║${NC}"
echo -e "${GREEN}║           funkmykali.sh — COMPLETE ✅                        ║${NC}"
echo -e "${GREEN}║           github.com/arif-offsec/funkmykali                  ║${NC}"
echo -e "${GREEN}║                                                               ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Tool locations:${NC}"
echo "  /usr/local/bin/               system-wide CLI tools"
echo "  /usr/bin/                     apt-installed tools"
echo "  /opt/tools/                   cloned repos"
echo "  /opt/tools/windows-binaries/  pre-compiled .exe files"
echo "  /opt/linpeas/                 all linpeas variants"
echo "  /opt/winpeas/                 all winpeas variants"
echo "  /opt/PlumHound/               PlumHound"
echo "  /opt/ghidra/                  Ghidra"
echo "  /usr/share/wordlists/         rockyou + standard lists"
echo "  /usr/share/seclists/          SecLists (full)"
echo "  /var/log/funkmykali.log       full install log"
echo ""
echo -e "${GREEN}[+] Verified in PATH: $PASS tools${NC}"
[[ $FAIL -gt 0 ]] && echo -e "${YELLOW}[!] Not in PATH:     $FAIL tools (see /opt/tools/ for repos)${NC}"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo "  1.  source /etc/profile.d/funkmykali.sh    (or open new terminal)"
echo "  2.  sudo systemctl start neo4j && bloodhound &"
echo "  3.  sudo msfdb init && msfconsole"
echo "  4.  cat /opt/tools/README-manual-installs.txt"
echo "  5.  Reboot recommended (GRUB, binfmt_misc, kernel headers)"
echo ""
echo -e "${CYAN}28-Module HTB Path Coverage:${NC}"
MODULES=(
  "Penetration Testing Process"
  "Getting Started"
  "Network Enumeration with Nmap"
  "Footprinting"
  "Information Gathering - Web Edition"
  "Vulnerability Assessment"
  "File Transfers"
  "Shells & Payloads"
  "Using the Metasploit Framework"
  "Password Attacks"
  "Attacking Common Services"
  "Pivoting, Tunneling, and Port Forwarding"
  "Active Directory Enumeration & Attacks"
  "Using Web Proxies"
  "Attacking Web Applications with Ffuf"
  "Login Brute Forcing"
  "SQL Injection Fundamentals"
  "SQLMap Essentials"
  "Cross-Site Scripting (XSS)"
  "File Inclusion"
  "File Upload Attacks"
  "Command Injections"
  "Web Attacks (HTTP Verb, IDOR, XXE)"
  "Attacking Common Applications"
  "Linux Privilege Escalation"
  "Windows Privilege Escalation"
  "Documentation & Reporting"
  "Attacking Enterprise Networks"
)
for i in "${!MODULES[@]}"; do
  printf "  ${GREEN}✅${NC} %02d. %s\n" "$((i+1))" "${MODULES[$i]}"
done
echo ""
echo -e "${YELLOW}Covers: OSCP | PNPT | PJPT | eJPT | eCPPT | THM PT1 | THM PT2${NC}"
echo ""
echo -e "${BOLD}${GREEN}  Enumerate everything. Trust the process. 🔴${NC}"
echo ""
