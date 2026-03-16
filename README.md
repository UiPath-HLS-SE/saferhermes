# OpenClaw Hardened - Quick Start
<img width="2752" height="1536" alt="Gemini_Generated_Image_bwoloibwoloibwol" src="https://github.com/user-attachments/assets/fb036668-c51f-4e26-99af-d3e07cc87aec" />

**Requirements:**

- Vagrant: https://developer.hashicorp.com/vagrant/install
- Virtualbox: https://www.virtualbox.org/wiki/Downloads
- Task: https://taskfile.dev/docs/installation

## 1. Setup (One Time)

```bash
task create
```

This will setup the virtual machine and start a sandboxed openclaw process inside it.
The tool will also guide you on what you need to do after that.

## 2. Add API Key for any model provider

```bash
task setup-models
```

## 4. Access

Run the following command to get the login link.
```bash
task login
```
---

## Security Rules

**ALWAYS:**
- Use dedicated bot accounts for integrations
- Rotate API keys every 30 days
- Keep human approval enabled
- Monitor audit logs

**NEVER:**
- Run as root or privileged
- Expose to 0.0.0.0
- Store tokens in plaintext config
- Allow DMs/group chats as control channels
