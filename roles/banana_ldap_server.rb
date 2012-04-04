name "banana_ldap_server"
description "Banana ldap server."
run_list "recipe[banana::common]", "recipe[banana::ldap_server]"
