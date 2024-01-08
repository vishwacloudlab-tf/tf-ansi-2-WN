provider "azurerm" {
      features {}
}

data "azurerm_resource_group" "rg01" {
  name = var.rg_name
}

resource "random_integer" "ri" {
  count = var.instance_count
  min = 1000
  max = 2999
}

resource "azurerm_virtual_network" "vnet" {
  count = var.create_Vnet ? 1 : 0
  #name                = "${var.location}-vnet"
  name                = var.virtual_network_name
  location            = data.azurerm_resource_group.rg01.location
  resource_group_name = data.azurerm_resource_group.rg01.name
  address_space       = var.address_space
  tags                = { env = var.tag_env }
  dns_servers         = var.dns_servers
}

resource "azurerm_subnet" "subnet" {
  count             = length(var.subnet_cidrs)
  #count             = (length(var.subnet_cidrs) != 0 ? length(var.subnet_cidrs) : 0)
  name                = format("%s-%s-%s", var.subnet_type, var.tag_env, var.subnet_name[count.index] )
  resource_group_name  = data.azurerm_resource_group.rg01.name
  #virtual_network_name = var.virtual_network_name
  virtual_network_name = length(azurerm_virtual_network.vnet) > 0 ? azurerm_virtual_network.vnet[0].name : var.virtual_network_name
  address_prefixes     = [var.subnet_cidrs[count.index]]
}

# Ansible-controller 

resource "azurerm_public_ip" "pips" {
  count = var.instance_count
  name                = "pip-${random_integer.ri[count.index].result}"
  resource_group_name = data.azurerm_resource_group.rg01.name
  location            = data.azurerm_resource_group.rg01.location
  allocation_method   = "Static"

  #tags = var.standard_tags["stnd_tag"]
}

resource "azurerm_network_interface" "main" {
  count = var.instance_count
  name                = "nic-${random_integer.ri[count.index].result}"
  location            = data.azurerm_resource_group.rg01.location
  resource_group_name = data.azurerm_resource_group.rg01.name

  ip_configuration {
    name                          = "nic-${random_integer.ri[count.index].result}"
    #making is simple to provision all the VM's in the same subnet
    subnet_id                     = azurerm_subnet.subnet[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pips[count.index].id
  }
}

resource "azurerm_virtual_machine" "main" {
  count = var.instance_count
  name                  = "${var.vm_name}-${random_integer.ri[count.index].result}"
  location              = data.azurerm_resource_group.rg01.location
  resource_group_name   = data.azurerm_resource_group.rg01.name
  network_interface_ids = [azurerm_network_interface.main[count.index].id]
  vm_size               = var.vm_size
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "${var.os_disk_name}-${random_integer.ri[count.index].result}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "${var.vm_name}-${random_integer.ri[count.index].result}"
    admin_username = var.admin_username
    admin_password = var.vm_pwd

  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = var.standard_tags["stnd_tag"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = var.name_nsg
  resource_group_name = data.azurerm_resource_group.rg01.name
  location            = data.azurerm_resource_group.rg01.location
  tags = var.standard_tags["stnd_tag"]
  
  dynamic "security_rule" {
    for_each = var.nsgrules 
    content {
      name                       = security_rule.value["name"] == "" ? "Default_Rule" : security_rule.value["name"]
      priority                   = security_rule.value["priority"]
      direction                  = security_rule.value["direction"] == "" ? "Inbound" : security_rule.value["direction"]
      access                     = security_rule.value["access"] == "" ? "Allow" : security_rule.value["access"]
      protocol                   = security_rule.value["protocol"] == "" ? "Tcp" : security_rule.value["protocol"]
      source_port_range          = "*"
      destination_port_range     = security_rule.value["destination_port_range"] == "" ? "*" : security_rule.value["destination_port_range"]
      source_address_prefix       =  security_rule.value["source_address_prefix"]
      destination_address_prefix =  security_rule.value["destination_address_prefix"]
      description                = "${security_rule.value["direction"]}_Port_${security_rule.value["destination_port_range"]}"
    }
  }
}

resource "azurerm_network_interface_security_group_association" "mySecGroupAssociation1" {
    count = var.instance_count
    network_interface_id      = azurerm_network_interface.main[count.index].id
    network_security_group_id = azurerm_network_security_group.nsg.id
}


resource "null_resource" "Copy_Scripts" {

  triggers = {
    always_run = timestamp()
  }
  connection {
      type = "ssh"
      user = var.admin_username
      password = var.vm_pwd
      host = azurerm_virtual_machine.main[0].public_ip
      timeout = "60s"
      agent = false  
    }
  provisioner "file" {
    source      = "scripts.sh"
    destination = "scripts.sh"
  }
  provisioner "file" {
    source      = "script-scp.sh"
    destination = "script-scp.sh"
  }
}

resource "null_resource" "Install_ansi_Setup" {

  triggers = {
    always_run = timestamp()
  }
  connection {
      type = "ssh"
      user = var.admin_username
      password = var.vm_pwd
      host = azurerm_virtual_machine.main[0].public_ip
      timeout = "60s"
      agent = false  
    }
  provisioner "remote-exec" {
    inline = [
      "sed -i 's/\r$//' scripts.sh",
      "sudo chmod 750 ~/scripts.sh",
      "./scripts.sh"
    ]
  }
}

resource "local_file" "hostfile" {
    content = templatefile("D:\\SR-batch-Nov23\\Test-Assesstment\\templates\\inventory.tpl",
    #content = templatefile("/home/obcot/Documents/repos/TF-ansi-proj-web-db/templates/inventory.tpl",
     {
       ansi_cont_pub = [azurerm_virtual_machine.main[0].public_ip]
       web_clients_pub = [azurerm_virtual_machine.main[1].public_ip]
       db_clients_pub = [azurerm_virtual_machine.main[2].public_ip]
       ansi-cont_pri = [azurerm_virtual_machine.main[0].private_ip]
       web_clients_pri = [azurerm_virtual_machine.main[1].private_ip]
       db_clients_pri = [azurerm_virtual_machine.main[2].private_ip]
       #web_clients = [module.VM-WN-01[*].public_ip]
       #db_clients = [module.VM-WN-01[*].public_ip]
     }

    )
    filename = "playbook/inventory"
}

locals {

  WN_publicip = azurerm_virtual_machine.main[*].public_ip
  WN_privateip = azurerm_virtual_machine.main[*].private_ip

}

resource "null_resource" "Copy_Public_key" {
  for_each = { for idx, ip in local.WN_publicip : idx => ip }
  triggers = {
    always_run = timestamp()
  }
  connection {
      type = "ssh"
      user = var.admin_username
      password = var.vm_pwd
      host = azurerm_virtual_machine.main[0].public_ip
      timeout = "60s"
      agent = false  
    }
  provisioner "remote-exec" {

    inline = [
      "sudo chmod 750 script-scp.sh",
      "./script-scp.sh ${var.vm_pwd} ${var.admin_username} ${each.value}",
      "ssh-keyscan -H ${each.value} >> ~/.ssh/known_hosts"
    ]

  }
  provisioner "file" {
    source      = "playbook"
    destination = "playbook"
  }

  depends_on = [ azurerm_network_security_group.nsg, azurerm_virtual_machine.main, null_resource.Install_ansi_Setup, local_file.hostfile]
}


resource "null_resource" "Ansi_Contro_playbook" {
  triggers = {
    always_run = timestamp()
  }
  connection {
      type = "ssh"
      user = var.admin_username
      password = var.vm_pwd
      host = azurerm_virtual_machine.main[0].public_ip
      timeout = "60s"
      agent = false  
    }
  provisioner "remote-exec" {

    inline = [
      "ansible-playbook -i playbook/inventory playbook/web-db.yml",
      "ansible-playbook -i playbook/inventory playbook/db.yml"
    ]
  }

  depends_on = [ module.NSG-VM, module.VM-01, null_resource.Install_ansi_Setup, local_file.hostfile, null_resource.Copy_Public_key]
}



