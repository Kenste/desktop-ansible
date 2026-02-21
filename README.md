# Desktop Ansible

Ansible playbook to replicate my desktop setup across fresh installs. Arch-first, with stubs for Fedora/Debian.

## Quick Start

```bash
# Fresh desktop: install everything + restore configs
./bootstrap.sh

# Laptop: skip gaming and communication packages
./bootstrap.sh deploy laptop

# Save current configs into the repo (before reinstall, or after tweaking settings)
./bootstrap.sh save

# Only install packages (skip config restore)
./bootstrap.sh packages

# Only restore configs (skip packages)
./bootstrap.sh configs
```

`bootstrap.sh` handles installing Ansible itself if it's not present.

### Prerequisites

- An AUR helper (`paru` or `yay`) must be installed for AUR packages. The playbook will fail with a clear message if none is found.

### Profiles

| Profile          | Groups                                         |
|------------------|------------------------------------------------|
| `full` (default) | desktop, browser, chat, voip, gaming, development |
| `laptop`         | desktop, browser, chat, development            |
| `minimal`        | desktop                                        |

Pass as second argument: `./bootstrap.sh deploy laptop`, `./bootstrap.sh packages minimal`, etc.
To add a new profile, edit `group_vars/all/settings.yml`.

## What It Does

### Package Groups

| Group       | Packages                          | Profiles     |
|-------------|-----------------------------------|--------------|
| desktop     | COSMIC DE (full suite)            | all          |
| browser     | Floorp                            | full, laptop |
| chat        | Vesktop                           | full, laptop |
| voip        | TeamSpeak 3                       | full         |
| gaming      | Steam, Prism Launcher, Faugus Launcher | full    |
| development | IntelliJ IDEA                     | full, laptop |

### Configs

Saves/restores dotfiles and app configs: COSMIC themes, Floorp profiles + SSB web apps,
Vesktop, PipeWire, JetBrains/IntelliJ, GTK, wallpapers, mimeapps. Hardcoded home paths are replaced with `@@HOME@@`
placeholders on save and resolved on restore, so configs work across different usernames.

### System

Enables NetworkManager/bluetooth/cosmic-greeter/pipewire services (missing services are skipped),
verifies COSMIC session is available. Services are enabled but not started — a reboot is required after deploy.

## Common Tasks

### Adding a new package

Edit `group_vars/all/packages.yml`:

```yaml
package_groups:
  # add to existing group or create new one
  tools:
    - name: btop
      arch: { repo: [ btop ] }
```

### Adding a new config to save/restore

Edit `group_vars/all/configs.yml`:

```yaml
config_entries:
  - name: my-app
    src: "{{ ansible_env.HOME }}/.config/my-app/"
    dest: "{{ playbook_dir }}/files/my-app/"
    excludes:
      - cache/
      - "*.log"
```

For single files instead of directories, add `is_file: true`.
For system paths (outside `$HOME`), add `system: true` — these are restored with `become`.

### Adding Fedora/Debian support

1. Add distro-specific package names in `packages.yml` (e.g. `fedora: { dnf: [package-name] }`)
2. Fill in the stub at `roles/packages/tasks/fedora.yml` or `debian.yml`

### Dry run (see what would change without doing anything)

```bash
cd ~/desktop-ansible
ansible-playbook site.yml --check --diff --ask-become-pass
```

### Run only specific parts

```bash
ansible-playbook site.yml --tags packages --ask-become-pass
ansible-playbook site.yml --tags configs --ask-become-pass
ansible-playbook site.yml --tags services --ask-become-pass
```

## Workflow

1. Set up system how you like it
2. `./bootstrap.sh save` to snapshot configs into `files/`
3. `git add -A && git commit -m "update configs"`
4. Push to a remote so you have it on fresh installs
5. On new system: clone repo, run `./bootstrap.sh`

## File Structure

```
group_vars/all/
  packages.yml    # what to install (per-distro mappings)
  configs.yml     # what configs to save/restore (paths + excludes)
  settings.yml    # services, profiles

roles/
  detect/         # figures out distro, user, AUR helper
  packages/       # installs packages (arch.yml, fedora.yml, debian.yml)
  configs/        # save.yml pulls configs into repo, restore.yml pushes them back
  desktop/        # verifies COSMIC is installed
  services/       # enables systemd services

files/            # stored configs (populated by ./bootstrap.sh save)
```
