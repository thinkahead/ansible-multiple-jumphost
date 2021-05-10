require 'rbconfig'
require 'yaml'

# Set your default base box here
DEFAULT_BASE_BOX = 'centos71-nocm'
DEFAULT_BASE_BOX_URL = 'https://tinfbo2.hogent.be/pub/vm/centos71-nocm-1.0.16.box'
VAGRANTFILE_API_VERSION = '2'
PROJECT_NAME = '/' + File.basename(Dir.getwd)

Vagrant.configure("2") do |config|

    # image/box
    config.vm.box = "generic/rhel8"

    # machine defaults
    config.vm.provider "virtualbox" do |vb|
      vb.cpus = "1"
      vb.memory = "1024"
    end

    # authentication
    config.ssh.insert_key = false
    config.vm.provision "file", source: "~/.ssh/vagrant_rsa.pub", destination: "~/.ssh/authorized_keys"

    # vagrant-hostmanager => manages /etc/hosts entries on host and guest machines
    if Vagrant.has_plugin?('vagrant-hostmanager')
      config.hostmanager.enabled = true
      config.hostmanager.manage_host = true
      config.hostmanager.manage_guest = true
      config.hostmanager.ignore_private_ip = false
      config.hostmanager.include_offline = false
    end

    # vagrant-vbguest => disable plugin to ignore virtualbox guest editions requirement
    config.vbguest.auto_update = false

    # vagrant-registration => auto register RHEL with subscription manager
    if Vagrant.has_plugin?('vagrant-registration')
      config.registration.unregister_on_halt = false
      config.registration.username = ENV['RHN_USERNAME']
      config.registration.password = ENV['RHN_PASSWORD']
    end

    # guest machines
    guests = {
      "jh1" => "192.168.34.10",
      "jh2" => "192.168.34.20",
      "jh3" => "192.168.34.30",
      "server" => "192.168.34.40"
    }

    guests.each do | name, ip|

      config.vm.define name do | machine |
        machine.vm.hostname = name + ".example.com"
        machine.vm.network :private_network, ip: ip
        machine.vm.provider "virtualbox" do | v |
            v.name = name
        end

        # Prepare simulated network device - Install Python3 and fake-switches project
        if ['jh3'].include?(name)
          machine.vm.provision :shell, path: "python3.sh"
        end

      end
    end
  
  end
