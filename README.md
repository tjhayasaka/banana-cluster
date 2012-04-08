banana-cluster - configuration scripts for banana HPC cluster

Banana is a HPC cluster being constructed at PFSL, Tohoku University.
Here we provide the configuration scripts of banana.

**DISCLAIMER:  NEVER EXPECT IT TO WORK FOR YOU AS IS**.  Adaptation is
mandatory because this software depends on many banana specific
details such as IP addresses, user names and NFS shares, and they are
provided as is.

Featuring:

  - ~5 users, ~40 nodes

  - chef, for centralized configuration management with git version
    control

  - ruby 1.9.2 with rvm, both for chef server and clients

  - Debian GNU Linux 6.0 (squeeze) at the base, both for master and
    compute nodes

  - Nvidia GPU with CUDA 4.1

  - QLogic QME7342 InfiniBand adapters with OFED 1.5.4.1

  - slurm as a job scheduler / resource manager

  - LDAP for user account directory, yet converted from
    easy-to-maintain flat "passwd" file

  - no public documentation at all (yet) :-<

License
=======

Note that following third party components are licensed separately:

  - chef-repo/cookbooks/apache2/
  - chef-repo/cookbooks/banana/files/default/OFED-1.5.4.1.tgz

For banana part:

Copyright:: 2012, Tomoaki Hayasaka

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
