name "banana_dhcp_server"
description "Banana dhcp server."
run_list "recipe[banana::common]", "recipe[banana::dhcp_server]"
