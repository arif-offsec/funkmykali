# Contributing to funkmykali

First off — thanks for considering a contribution. This project only stays useful if the community keeps it current, and that means you.

Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before participating.

---

## Ways to Contribute

- **Suggest a missing tool** — open a [Tool Suggestion issue](../../issues/new/choose)
- **Report a bug** — open a [Bug Report issue](../../issues/new/choose) (check `/var/log/funkmykali.log` first)
- **Fix a broken install step** — tools get abandoned, renamed, or move repos; PRs that fix a dead link or broken build are always welcome
- **Improve documentation** — README clarity, typos, better explanations
- **Add a system fix** — the kind of thing pimpmykali does (config fixes, compatibility patches, hypervisor detection improvements)

You don't need to ask permission first — if it's a small fix, just open a PR.

---

## Before You Start

1. **Test on a disposable Kali VM, not your daily driver.** The script modifies GRUB, SMB config, sources.list, and system services. Snapshot your VM before testing so you can roll back.
2. Fork the repo and clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/funkmykali.git
   cd funkmykali
   ```
3. Create a branch:
   ```bash
   git checkout -b add-tool-name
   ```

---

## Adding a New Tool

Every tool in `funkmykali.sh` goes through one of the safe wrapper functions defined near the top of the script. **Never call `apt install`, `pip install`, or `git clone` directly** — this is what keeps the script from ever hard-crashing on a single failed install.

| Wrapper | Use for |
|---|---|
| `apt_install pkg1 pkg2 ...` | Debian/Kali apt packages |
| `pip_install toolname` | Python CLI tools (tries pipx, falls back to pip3) |
| `pip3_install pkg1 pkg2 ...` | Python libraries (not standalone CLIs) |
| `pip_req /path/requirements.txt` | Installing a repo's requirements.txt |
| `gem_install gemname` | Ruby gems |
| `go_install github.com/x/y@latest` | Go-based tools |
| `git_clone "url" "$TOOLS/RepoName"` | Cloning a GitHub repo (idempotent — safe to re-run) |
| `safe_wget "url" "output_path"` | Downloading a single file |
| `gh_latest "owner/repo" "pattern" "output_path"` | Grabbing the latest GitHub release asset matching a regex |
| `make_link "src" "dest"` | Symlinking a script into PATH |
| `make_wrapper "script.py" "/usr/local/bin/name"` | Creating a `/usr/local/bin/` wrapper for a Python tool so it runs as a bare command |

### Example: adding a new Python-based tool

```bash
# Clone it
TOOLNAME="$TOOLS/ToolName"
git_clone "https://github.com/author/ToolName.git" "$TOOLNAME"

# Install its dependencies
pip_req "$TOOLNAME/requirements.txt"

# Make it callable system-wide as a bare command
make_wrapper "$TOOLNAME/toolname.py" "/usr/local/bin/toolname"
```

### Where to add it

Find the `section "STEP N — ..."` block that matches the tool's category (Active Directory, Web Application, Privilege Escalation, etc.) and add it there. If it doesn't fit an existing category, open an issue first to discuss whether it needs a new section.

### Don't forget

- Add the tool's command name to the `CRITICAL=(...)` array in the **Final Verification** step, so the end-of-run check confirms it installed correctly
- Add it to the relevant category list in `README.md`
- If it needs a manual step (Docker, GUI install, license key), add a note to the `README-manual-installs.txt` heredoc instead of trying to force-automate it

---

## Script Style Rules

These exist because the whole point of funkmykali is that it **never stops halfway through**:

1. Every install call must go through a wrapper — no bare `apt-get install` or `pip install`
2. Every `git clone` must be idempotent (use `git_clone`, which skips/updates existing repos instead of failing)
3. Never use `set -e` behavior for individual commands — failures should `warn` and continue, not exit
4. Test the full script end-to-end on a clean VM before submitting, not just the section you touched — a change near the top can affect PATH or variables used later
5. Run `bash -n funkmykali.sh` before committing to catch syntax errors:
   ```bash
   bash -n funkmykali.sh && echo "Syntax OK"
   ```

---

## Commit Messages

Keep them short and specific:

```
Add Certipy-ng as Certipy successor
Fix broken LinkFinder requirements.txt path
Update README: add Snaffler to PrivEsc section
```

Avoid vague messages like `update` or `fix stuff`.

---

## Submitting a Pull Request

1. Push your branch and open a PR against `main`
2. Describe **what** you changed and **why** — link to the tool's GitHub repo if adding something new
3. Confirm in the PR description that you tested it on a real Kali VM (which variant, which version)
4. One logical change per PR is easier to review than a bundle of unrelated fixes

A maintainer will review and merge, or ask for changes. Be patient — this is maintained in spare time.

---

## Scope Reminder

This project installs tooling for **authorized** penetration testing and certification labs (HTB, OffSec, TCM Security, INE, TryHackMe). PRs that add functionality primarily useful for unauthorized access or harming others will be declined — see [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

---

Questions? Open a [Discussion](../../discussions) rather than an issue if it's not a concrete bug or tool suggestion.

Thanks again for contributing. 🔴
