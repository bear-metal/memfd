Vagrant.configure(2) do |config|
  config.vm.box = "geerlingguy/ubuntu1404"

  config.vm.provider "virtualbox" do |box|
    box.memory = 512
    box.cpus = 1
  end

  config.vm.synced_folder ".", "/vagrant", type: "nfs"
  config.vm.network :private_network, ip: "192.168.22.10"
end