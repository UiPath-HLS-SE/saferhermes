# Sandbox images for SaferHermes

The base Dockerfiles are intentionally minimal. They are used by the Hermes
Docker terminal backend to keep command execution inside disposable containers
while the gateway and git repos remain on the VM host.

The browser image is optional and kept for future browser-tool use. The
default `hermes.config.yaml` points at the non-browser image.
