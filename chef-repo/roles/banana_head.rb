name "banana_head"
description "Banana head."
run_list "recipe[banana::common]", "recipe[banana::ldap_server]", "recipe[banana::dhcp_server]", "recipe[banana::tftp_server]", "recipe[banana::debian_preseeder]"
