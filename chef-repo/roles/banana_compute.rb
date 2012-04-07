name "banana_compute"
description "Banana compute node."
run_list "recipe[banana::common]", "recipe[banana::dhcp_client]", "recipe[banana::compute]"
