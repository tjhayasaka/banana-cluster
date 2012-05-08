name "banana_compute_hostgroup_vine2"
description "Banana compute node."
run_list "recipe[banana::common]", "recipe[banana::dhcp_client]", "recipe[banana::compute]", "recipe[banana::slurm]", "recipe[banana::openmpi_1_4_2_eth]"
