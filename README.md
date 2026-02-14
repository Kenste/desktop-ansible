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

### Profiles

| Profile          | Groups                                                   |
|------------------|----------------------------------------------------------|
| `full` (default) | desktop, browser, chat, voip, gaming, development, shell |
| `laptop`         | desktop, browser, chat, development, shell               |
| `minimal`        | desktop, shell                                           |

Pass as second argument: `./bootstrap.sh deploy laptop`, `./bootstrap.sh packages minimal`, etc.
To add a new profile, edit `group_vars/all/settings.yml`.

## What It Does

### Package Groups

| Group       | Packages               | Profiles     |
|-------------|------------------------|--------------|
| desktop     | COSMIC DE (full suite) | all          |
| browser     | Floorp                 | full, laptop |
| chat        | Vesktop                | full, laptop |
| voip        | TeamSpeak 3            | full         |
| gaming      | Steam, Faugus Launcher | full         |
| development | IntelliJ IDEA          | full, laptop |
| shell       | Fish                   | all          |

### Configs

Saves/restores dotfiles and app configs: COSMIC themes, Fish, Floorp profiles, Vesktop, Steam, PipeWire,
JetBrains/IntelliJ, GTK, mimeapps. Excludes caches, session data, cookies, crash dumps.

### System

Sets Fish as default shell, enables NetworkManager/bluetooth/pipewire services, verifies COSMIC session is available.

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
ansible-playbook site.yml --tags shell --ask-become-pass
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
  settings.yml    # services, shell preference, AUR helper

roles/
  detect/         # figures out distro, user, AUR helper
  packages/       # installs packages (arch.yml, fedora.yml, debian.yml)
  configs/        # save.yml pulls configs into repo, restore.yml pushes them back
  shell/          # sets fish as default shell
  desktop/        # verifies COSMIC is installed
  services/       # enables systemd services

files/            # stored configs (populated by ./bootstrap.sh save)
```
