name "banana_ofed_1_5_4_1"
description "Add OFED 1.5.4.1 support to use InfiniBand adaptors."
run_list "recipe[banana::common]", "recipe[banana::ofed_1_5_4_1]"
