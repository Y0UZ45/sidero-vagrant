CONFIG_DNS_DOMAIN = 'sidero.test'
CONFIG_CAPI_VERSION = '1.0.4'                                   # see https://github.com/kubernetes-sigs/cluster-api/releases (see the sigs.k8s.io/cluster-api dependency in the sidero release notes)
CONFIG_CAPI_BOOTSTRAP_PROVIDER = 'talos:v0.5.3'                 # see https://github.com/siderolabs/cluster-api-bootstrap-provider-talos/releases
CONFIG_CAPI_CONTROL_PLANE_PROVIDER = 'talos:v0.4.6'             # see https://github.com/siderolabs/cluster-api-control-plane-provider-talos/releases
CONFIG_CAPI_INFRASTRUCTURE_PROVIDER = 'sidero:v0.5.0'           # see https://github.com/siderolabs/sidero/releases
CONFIG_TALOS_VERSION = '1.0.5'                                  # see https://github.com/siderolabs/talos/releases
CONFIG_THEILA_TAG = 'v0.2.1'                                    # see https://github.com/siderolabs/theila/releases
CONFIG_KUBERNETES_VERSION = '1.23.6'                            # see https://github.com/siderolabs/talos/releases (see the talos release notes)
CONFIG_KUBERNETES_DASHBOARD_TAG = 'v2.5.1'                      # see https://github.com/kubernetes/dashboard/releases
CONFIG_K9S_TAG = 'v0.25.18'                                     # see https://github.com/derailed/k9s/releases

# connect to the internal virtual network.
CONFIG_PANDORA_BRIDGE_NAME = nil
CONFIG_PANDORA_HOST_IP = '10.10.0.1'
CONFIG_PANDORA_IP = '10.10.0.2'
CONFIG_PANDORA_DHCP_RANGE = '10.10.0.100,10.10.0.200,10m'

# connect to the external physical network through the given bridge.
# NB uncomment this block when using a bridge.
# CONFIG_PANDORA_BRIDGE_NAME = 'br-rpi'
# CONFIG_PANDORA_HOST_IP = '10.3.0.1'
# CONFIG_PANDORA_IP = '10.3.0.2'
# CONFIG_PANDORA_DHCP_RANGE = '10.3.0.100,10.3.0.200,10m'

# this environment is used in all the provision steps.
PROVISION_ENV = ENV.select do |k, v|
  # GITHUB_TOKEN should be a GitHub account Personal Access Token without any
  # scope selected (it will show up as having "public access" in GH UI).
  # this is used to have an higher GitHub download rate limit.
  k =~ /^GITHUB_(USERNAME|TOKEN)$/
end

require './lib.rb'

Vagrant.configure('2') do |config|
  config.vm.box = 'alvistack/ubuntu-20.04'

  config.vm.provider :libvirt do |lv, config|
    lv.cpus = 2
    #lv.cpu_mode = 'host-passthrough'
    #lv.nested = true
    lv.memory = 2*1024
    lv.keymap = 'pt'
    config.vm.synced_folder '.', '/vagrant', type: 'nfs', nfs_version: '4.2', nfs_udp: false
  end

  config.vm.define :pandora do |config|
    config.vm.provider :libvirt do |lv|
      lv.cpus = 4
      lv.memory = 4*1024
    end
    config.vm.hostname = "pandora.#{CONFIG_DNS_DOMAIN}"
    if CONFIG_PANDORA_BRIDGE_NAME
      config.vm.network :public_network,
        dev: CONFIG_PANDORA_BRIDGE_NAME,
        mode: 'bridge',
        type: 'bridge',
        ip: CONFIG_PANDORA_IP
    else
      config.vm.network :private_network,
        ip: CONFIG_PANDORA_IP,
        libvirt__dhcp_enabled: false,
        libvirt__forward_mode: 'none'
    end
    config.vm.provision :shell, path: 'provision-base.sh', env: PROVISION_ENV
    config.vm.provision :shell, path: 'provision-chrony.sh', env: PROVISION_ENV
    config.vm.provision :shell, path: 'provision-iptables.sh', env: PROVISION_ENV
    config.vm.provision :shell, path: 'provision-docker.sh', env: PROVISION_ENV
    config.vm.provision :shell, path: 'provision-dnsmasq.sh', args: [CONFIG_PANDORA_IP, CONFIG_PANDORA_DHCP_RANGE], env: PROVISION_ENV
    config.vm.provision :shell, path: 'provision-k9s.sh', args: [CONFIG_K9S_TAG], env: PROVISION_ENV
    config.vm.provision :shell, path: 'provision-kubectl.sh', args: [CONFIG_KUBERNETES_VERSION], env: PROVISION_ENV
    config.vm.provision :shell, path: 'provision-clusterctl.sh', args: [CONFIG_CAPI_VERSION], env: PROVISION_ENV
    config.vm.provision :shell, path: 'provision-talosctl.sh', args: [CONFIG_TALOS_VERSION], env: PROVISION_ENV
    config.vm.provision :shell, path: 'provision-sidero.sh', args: [CONFIG_PANDORA_IP, CONFIG_CAPI_VERSION, CONFIG_CAPI_BOOTSTRAP_PROVIDER, CONFIG_CAPI_CONTROL_PLANE_PROVIDER, CONFIG_CAPI_INFRASTRUCTURE_PROVIDER, CONFIG_TALOS_VERSION, CONFIG_KUBERNETES_VERSION], env: PROVISION_ENV
    config.vm.provision :shell, path: 'provision-theila.sh', args: [CONFIG_THEILA_TAG], env: PROVISION_ENV
    config.vm.provision :shell, path: 'provision-k8s-dashboard.sh', args: [CONFIG_KUBERNETES_DASHBOARD_TAG], env: PROVISION_ENV
    config.vm.provision :shell, path: 'provision-machines.sh', env: PROVISION_ENV
    config.vm.provision :shell, path: 'provision-example-cluster.sh', args: [CONFIG_CAPI_INFRASTRUCTURE_PROVIDER, CONFIG_TALOS_VERSION, CONFIG_KUBERNETES_VERSION], env: PROVISION_ENV
    config.vm.provision :shell, inline: 'docker start sidero-master-1', run: 'always', name: 'start sidero', env: PROVISION_ENV
    config.vm.provision :shell, path: 'summary.sh', run: 'always', env: PROVISION_ENV
  end

  virtual_machines.each do |name, arch, firmware, ip, uuid, mac, bmc_ip, bmc_port, bmc_qmp_port|
    config.vm.define name do |config|
      config.vm.box = nil
      config.vm.provider :libvirt do |lv, config|
        lv.loader = '/usr/share/ovmf/OVMF.fd' if firmware == 'uefi'
        lv.boot 'hd'
        lv.boot 'network'
        lv.storage :file, :size => '40G'
        if CONFIG_PANDORA_BRIDGE_NAME
          config.vm.network :public_network,
            dev: CONFIG_PANDORA_BRIDGE_NAME,
            mode: 'bridge',
            type: 'bridge',
            mac: mac,
            ip: ip,
            auto_config: false
        else
          config.vm.network :private_network,
            mac: mac,
            ip: ip,
            auto_config: false
        end
        lv.mgmt_attach = false
        lv.graphics_type = 'spice'
        lv.video_type = 'virtio'
        # set some BIOS settings that will help us identify this particular machine.
        #
        #   QEMU                | Linux
        #   --------------------+----------------------------------------------
        #   type=1,manufacturer | /sys/devices/virtual/dmi/id/sys_vendor
        #   type=1,product      | /sys/devices/virtual/dmi/id/product_name
        #   type=1,version      | /sys/devices/virtual/dmi/id/product_version
        #   type=1,serial       | /sys/devices/virtual/dmi/id/product_serial
        #   type=1,sku          | dmidecode
        #   type=1,uuid         | /sys/devices/virtual/dmi/id/product_uuid
        #   type=3,manufacturer | /sys/devices/virtual/dmi/id/chassis_vendor
        #   type=3,family       | /sys/devices/virtual/dmi/id/chassis_type
        #   type=3,version      | /sys/devices/virtual/dmi/id/chassis_version
        #   type=3,serial       | /sys/devices/virtual/dmi/id/chassis_serial
        #   type=3,asset        | /sys/devices/virtual/dmi/id/chassis_asset_tag
        [
          'type=1,manufacturer=your vendor name here',
          'type=1,product=your product name here',
          'type=1,version=your product version here',
          'type=1,serial=your product serial number here',
          'type=1,sku=your product SKU here',
          "type=1,uuid=#{uuid}",
          'type=3,manufacturer=your chassis vendor name here',
          #'type=3,family=1', # TODO why this does not work on qemu from ubuntu 18.04?
          'type=3,version=your chassis version here',
          'type=3,serial=your chassis serial number here',
          "type=3,asset=your chassis asset tag here #{name}",
        ].each do |value|
          lv.qemuargs :value => '-smbios'
          lv.qemuargs :value => value
        end
        # expose the VM QMP socket.
        # see https://gist.github.com/rgl/dc38c6875a53469fdebb2e9c0a220c6c
        lv.qemuargs :value => '-qmp'
        lv.qemuargs :value => "tcp:#{bmc_ip}:#{bmc_qmp_port},server,nowait"
        config.vm.synced_folder '.', '/vagrant', disabled: true
        config.trigger.after :up do |trigger|
          trigger.ruby do |env, machine|
            vbmc_up(machine, bmc_ip, bmc_port)
          end
        end
        config.trigger.after :destroy do |trigger|
          trigger.ruby do |env, machine|
            vbmc_destroy(machine)
          end
        end
      end
    end
  end
end
