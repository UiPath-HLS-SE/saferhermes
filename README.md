# SaferHermes
<img width="206" height="375" alt="Safer Hermes logo" src="./logo.png" />

`saferhermes` is a fork of `saferclaw` that keeps the same hardened appliance
shape while swapping the agent runtime from OpenClaw to Hermes.

The goal is the same:

- run the agent inside a dedicated VM
- keep the gateway under a locked-down `systemd` unit
- isolate command execution behind Docker sandboxes
- ship service logs off-box
- make long-running work resumable and branch-local

The Hermes-specific additions are:

- `worktree: true` by default so each repo session gets its own git worktree
- a dedicated `/srv/repos` root for controlled repo clones
- task helpers for interactive repo sessions and long-running gateway use
- a conservative starter command allowlist tuned for repo work

## Requirements

Install these before continuing:

- Vagrant: https://developer.hashicorp.com/vagrant/install
- VirtualBox: https://www.virtualbox.org/wiki/Downloads
- Task: https://taskfile.dev/docs/installation

## Quick Start

### 1. Provision the appliance

This creates the VM, installs Hermes plus supporting packages, builds the
Docker sandbox image, configures logging, and starts the `saferhermes`
service.

```bash
task create
```

### 2. Configure Hermes

Run the interactive Hermes setup once to add model providers and any messaging
gateways you want the service to use.

```bash
task setup-gateway
task setup-models
```

### 3. Clone a repo into the appliance

```bash
task repo:clone REPO_URL=https://github.com/UiPath-HLS-SE/acfc-care-coordination.git DEST_NAME=acfc-care-coordination
```

### 4. Start a branch-isolated repo session

This launches Hermes inside the target repo with worktree isolation enabled.

```bash
task session:new REPO=/srv/repos/acfc-care-coordination
```

To resume later from a fresh shell:

```bash
task session:continue REPO=/srv/repos/acfc-care-coordination
```

## Operating Model

`saferhermes` is intended for long-running agent work where you want the agent
to keep operating while the human hops across contexts.

Recommended pattern:

1. Run the Hermes gateway as a background service inside the VM.
2. Keep target repos under `/srv/repos`.
3. Always operate from repo roots with `worktree: true`.
4. Commit frequently on branch-local worktrees, but do not auto-push.
5. Treat the repo state, session files, and handoff notes as the continuity
   layer rather than depending on one giant chat transcript.

## Security Notes

**Always:**

- use dedicated bot accounts for Slack or Telegram integrations
- keep the VM separate from your workstation repo clones
- review and tighten `command_allowlist` in [`vagrant/hermes.config.yaml`](./vagrant/hermes.config.yaml)
- monitor `journalctl -u saferhermes` and Azure-shipped logs

**Never:**

- run the gateway as root
- allow direct host writes outside `/srv/repos` and the Hermes state dir
- give the default allowlist `git push` or cloud-deployment commands
- reuse the same branch for unrelated long-running experiments
