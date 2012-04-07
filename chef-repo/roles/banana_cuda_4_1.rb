name "banana_cuda_4_1"
description "Add CUDA 4.1 support."
run_list "recipe[banana::common]", "recipe[banana::cuda_4_1]"
