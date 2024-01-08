# Genral Values
tag_env = "dev"
rg_name = "rg01"

# Vnet Values
virtual_network_name = "vnet02"
create_Vnet = false

# Subnet Values
subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
subnet_name = ["Ansi-Cont", "Worker1-node"]
subnet_type = "public"

instance_count = 3
vm_name = "p1-VM"
os_disk_name = "os_disk"
vm_size = "Standard_DS1_v2"

name_nsg = "nsg001"

standard_tags = {
    stnd_tag = {
        Env   = "Dev"
        Owner = "V"
        Project = "p1"
        Location = "East us"
    }
}


nsgrules = [
  {
  name                       = "AllowWebIn"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "80"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  },
  {
  name                       = "AllowSSHIn"
  priority                   = 110
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  },
  {
  name                       = "Allow8080In"
  priority                   = 120
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "8080"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  },
  {
  name                       = "Allow90In"
  priority                   = 130
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "90"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  }
]