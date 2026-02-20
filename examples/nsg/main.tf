module "nsg" {
  source = "./module/nsg"
  
  nsg_predefined_rules = ["pre1", "pre3"]
}

module "nsg2" {
  source = "./module/nsg"
  
  nsg_predefined_rules = ["pre3"]
  nsg_name = "nsg2"
}

output "mod" {
  value = module.nsg.filecontent
}
