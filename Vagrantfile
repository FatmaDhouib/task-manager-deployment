# Vagrantfile
Vagrant.configure("2") do |config|
  # Use Ubuntu 22.04 (Jammy) - available on Vagrant Cloud
  config.vm.box = "ubuntu/jammy64"
  
  # Master node
  config.vm.define "master" do |master|
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: "192.168.56.10"
    master.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
    end
  end

  # Worker node 1
  config.vm.define "worker1" do |worker1|
    worker1.vm.hostname = "worker1"
    worker1.vm.network "private_network", ip: "192.168.56.11"
    worker1.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 1
    end
  end

  # Worker node 2
  config.vm.define "worker2" do |worker2|
    worker2.vm.hostname = "worker2"
    worker2.vm.network "private_network", ip: "192.168.56.12"
    worker2.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 1
    end
  end

  # Ansible provisioning
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "ansible/playbook.yml"
    ansible.inventory_path = "ansible/inventory.yml"
    ansible.limit = "all"
    ansible.compatibility_mode = "2.0"
  end
end