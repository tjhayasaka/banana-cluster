name "banana_tftp_server"
description "Banana tftp server."
run_list "recipe[banana::common]", "recipe[banana::tftp_server]"
