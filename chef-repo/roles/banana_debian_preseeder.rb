name "banana_debian_preseeder"
description "Banana Debian preseeder."
run_list "recipe[banana::common]", "recipe[banana::debian_preseeder]"
