# -*- mode: ruby -*-
# vi: set ft=ruby :

AZURE_SUBSCRIPTION_ID = "f65321ce-fb9c-42a0-afe6-68ee26440d72"
AZURE_BLOB_ACCOUNT_NAME = "clawdbotevents"
DEFENDER_SETUP_SCRIPT_URL = "https://dfescripts.blob.core.windows.net/dfelinuxscript/MicrosoftDefenderATPOnboardingLinuxServer.py?sp=r&st=2026-04-03T11:09:34Z&se=2028-06-09T19:24:34Z&spr=https&sv=2024-11-04&sr=c&sig=5Tr4H096BLQct1e%2B91ah4G47kEoGByNPqTzYSPuohCA%3D"
ENABLE_AZURE_LOGGING = ENV.fetch("ENABLE_AZURE_LOGGING", "false")

unless File.respond_to?(:exists?)
  class << File
    def exists?(path)
      exist?(path)
    end
  end
end

SAFERHERMES_ENV_PATH = "/etc/saferhermes/service.env"

Vagrant.configure("2") do |config|
  config.vm.define "saferhermes" do |vm|
    vm.vm.box = "bento/debian-13"
    vm.vm.box_version = "202510.26.0"

    vm.vm.provider "virtualbox" do |vb|
      vb.gui = false
      vb.memory = "4096"
      vb.check_guest_additions = false
      if Vagrant.has_plugin?("vagrant-vbguest")
        config.vbguest.auto_update = false
      end
    end

    vm.ssh.shell = "bash"
    vm.vm.synced_folder ".", "/vagrant", disabled: true

    vm.vm.provision "shell" do |s|
      s.privileged = true
      s.name = "set-dns-nameservers"
      s.inline = <<-SCRIPT
        echo "nameserver 1.1.1.1" > /etc/resolv.conf.head
        echo "nameserver 8.8.8.8" >> /etc/resolv.conf.head
      SCRIPT
    end

    vm.vm.provision "shell" do |s|
      s.privileged = true
      s.name = "create-service-user"
      s.inline = <<-SCRIPT
        grep -q saferhermes /etc/group || groupadd -g 10001 saferhermes
        grep -q saferhermes /etc/passwd || useradd -u 10001 -g saferhermes -d /var/lib/saferhermes -s /usr/sbin/nologin -m saferhermes
        mkdir -p /srv/repos
        chown saferhermes:saferhermes /srv/repos
        chmod 750 /srv/repos
      SCRIPT
    end

    vm.vm.provision "shell" do |s|
      s.privileged = true
      s.name = "install-dependencies"
      s.env = {
        "ENV" => "$HOME/.bashrc",
        "DEBIAN_FRONTEND" => "noninteractive",
        "AZURE_SUBSCRIPTION_ID" => AZURE_SUBSCRIPTION_ID,
        "DEFENDER_SETUP_SCRIPT_URL" => DEFENDER_SETUP_SCRIPT_URL,
      }
      s.path = "./vagrant/install-deps.sh"
    end

    vm.vm.provision "docker"
    vm.vm.provision "file" do |file|
      file.source = "vagrant/docker"
      file.destination = "/tmp/saferhermes-docker-sandbox"
    end
    vm.vm.provision "shell" do |s|
      s.privileged = true
      s.name = "build-docker-sandbox"
      s.inline = <<-SCRIPT
        cd /tmp/saferhermes-docker-sandbox
        bash scripts/sandbox-setup.sh
        bash scripts/sandbox-browser-setup.sh
        rm -rf /tmp/saferhermes-docker-sandbox
      SCRIPT
    end

    vm.vm.provision "file" do |file|
      file.source = "vagrant/hermes.config.yaml"
      file.destination = "/tmp/saferhermes/config.yaml"
    end
    vm.vm.provision "file" do |file|
      file.source = "vagrant/saferhermes-startup.sh"
      file.destination = "/tmp/saferhermes/startup.sh"
    end
    vm.vm.provision "file" do |file|
      file.source = "vagrant/saferhermes.service"
      file.destination = "/tmp/saferhermes/saferhermes.service"
    end
    vm.vm.provision "file" do |file|
      file.source = "vagrant/saferhermes.service.env"
      file.destination = "/tmp/saferhermes/saferhermes.service.env"
    end
    vm.vm.provision "file" do |file|
      file.source = "vagrant/fluentbit.yaml"
      file.destination = "/tmp/fluentbit/conf.yaml"
    end
    vm.vm.provision "file" do |file|
      file.source = "vagrant/setup-azure-monitor.sh"
      file.destination = "~/utils/setup-azure-monitor.sh"
    end
    vm.vm.provision "shell" do |s|
      s.privileged = false
      s.name = "copy-config"
      s.inline = <<-SCRIPT
        sudo mkdir -p /etc/saferhermes /etc/fluent-bit /var/lib/saferhermes/.hermes
        sudo mv /tmp/saferhermes/saferhermes.service /etc/systemd/system/saferhermes.service
        sudo mv /tmp/saferhermes/startup.sh /etc/saferhermes/startup.sh
        sudo mv /tmp/saferhermes/saferhermes.service.env #{SAFERHERMES_ENV_PATH}
        sudo mv /tmp/saferhermes/config.yaml /var/lib/saferhermes/.hermes/config.yaml
        sudo rm -rf /tmp/saferhermes

        sudo chmod 750 /etc/saferhermes
        sudo chown -R root:saferhermes /etc/saferhermes
        sudo chmod 550 /etc/saferhermes/startup.sh
        sudo chown -R saferhermes:saferhermes /var/lib/saferhermes
        sudo chmod 700 /var/lib/saferhermes/.hermes
        sudo touch /var/lib/saferhermes/.hermes/.env
        sudo chown saferhermes:saferhermes /var/lib/saferhermes/.hermes/.env
        sudo chmod 600 /var/lib/saferhermes/.hermes/.env

        sudo mv /tmp/fluentbit/conf.yaml /etc/fluent-bit/conf.yaml
        chmod +x ~/utils/setup-azure-monitor.sh
      SCRIPT
    end

    vm.trigger.after :up do |trigger|
      trigger.name = "bootstrap-hermes-home"
      trigger.info = "Preparing Hermes state directories"
      trigger.run_remote = {
        path: "./vagrant/migrations.sh"
      }
    end

    vm.trigger.after :up, :reload do |trigger|
      trigger.name = "start-service"
      trigger.info = "Running post-boot setup"
      trigger.run_remote = {
        privileged: true,
        env: {
          "ENABLE_AZURE_LOGGING" => ENABLE_AZURE_LOGGING,
          "AZURE_SUBSCRIPTION_ID" => AZURE_SUBSCRIPTION_ID,
          "AZURE_BLOB_ACCOUNT_NAME" => AZURE_BLOB_ACCOUNT_NAME,
        },
        path: "./vagrant/post-boot-setup.sh"
      }
    end
  end
end
