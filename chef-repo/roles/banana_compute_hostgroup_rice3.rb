name "banana_compute_hostgroup_rice3"
description "Banana compute node with ib and cuda."
run_list "recipe[banana::common]", "recipe[banana::dhcp_client]", "recipe[banana::compute]", "recipe[banana::slurm]", "recipe[banana::ofed_1_5_4_1]", "recipe[banana::cuda_4_1]"
