locals {
  predefined_rules = {
    pre1 = [
      "Inbound", 
      "CDefault", 
      "2000", 
      "Deny", 
      "*", 
      "Deny-pre1", 
      ["10.242.32.0/26", "10.242.32.64/26", "10.242.32.128/25", "10.242.45.0/24", "10.242.46.0/23", "10.242.195.128/26", "10.242.199.128/25", "10.242.206.0/24", "10.242.207.0/24"], 
      "*", 
      "*", 
      "*"]
      
    pre2      = ["Inbound", "CUsrDEBANK", "2001", "Deny", "*", "Deny-pre1", ["10.242.33.0/24", "10.242.34.0/23", "10.242.36.0/22", "10.242.40.0/22", "10.242.44.0/24"], "*", "*", "*"]
    pre3       = ["Inbound", "CAVAdmin", "2002", "Deny", "*", "Deny-pre3", ["10.242.192.0/24"], "*", "*", "*"]
  }
  





  
  # Read ALL files from configs/ folder (glob pattern)
  config_files = fileset("./module/nsg/config", "**/*.yaml")

  # Transform: filename → content map
  config_map = {
    for filename in local.config_files : filename => file("./module/nsg/config/${filename}")
  }
  
  config_yaml = {
    for filename, content in local.config_map : 
    replace(filename, ".yaml", "") => yamldecode(content)
  }
}

output "filecontent" {
  value = local.config_yaml
}
