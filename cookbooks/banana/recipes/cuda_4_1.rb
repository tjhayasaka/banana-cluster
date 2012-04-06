#
# Copyright 2012, Tomoaki Hayasaka
#

# NOTE:
#
#   Following files are not included in git repo.  They must be
#   downloaded separately and placed at /w2/hayasaka/files/non-free.
#
#     NVIDIA-Linux-x86_64-295.33.run
#     cudatoolkit_4.1.28_linux_64_ubuntu10.04.run
#     gpucomputingsdk_4.1.28_linux.run

package "linux-headers-" + `uname --kernel-release`.strip

execute "install_driver" do
  depends "/w2/hayasaka/files/non-free/NVIDIA-Linux-x86_64-295.33.run"
  stamps "NVIDIA-Linux-x86_64-295.33.run-installed"
  command "/usr/bin/env CC=gcc-4.3 /w2/hayasaka/files/non-free/NVIDIA-Linux-x86_64-295.33.run --accept-license --no-questions --no-precompiled-interface --ui=none"
end

execute "install_toolkit" do
  depends "/w2/hayasaka/files/non-free/cudatoolkit_4.1.28_linux_64_ubuntu10.04.run"
  stamps "cudatoolkit_4.1.28_linux_64_ubuntu10.04.run-installed"
  command "rm -fr /usr/local/cuda && /w2/hayasaka/files/non-free/cudatoolkit_4.1.28_linux_64_ubuntu10.04.run -- auto && rm -fv /root/stamps/gpucomputingsdk_4.1.28_linux.run-compiled"
end

execute "install_sdk" do
  depends "/w2/hayasaka/files/non-free/gpucomputingsdk_4.1.28_linux.run"
  stamps "gpucomputingsdk_4.1.28_linux.run-installed"
  command "rm -fr /usr/NVIDIA_GPU_Computing_SDK && /w2/hayasaka/files/non-free/gpucomputingsdk_4.1.28_linux.run -- --prefix=/usr/NVIDIA_GPU_Computing_SDK --cudaprefix=/usr/local/cuda"
end

file "/etc/ld.so.conf.d/cuda.conf" do
  owner "root"
  group "root"
  mode "0644"
  content <<EOS
/usr/local/cuda/lib
/usr/local/cuda/lib64
EOS
end

execute "ldconfig"

package "xorg-dev"
package "libglu1-mesa-dev"
package "freeglut3-dev"

execute "compile_sdk" do
  depends "gpucomputingsdk_4.1.28_linux.run-installed"
  stamps "gpucomputingsdk_4.1.28_linux.run-compiled"
  command "cd /usr/NVIDIA_GPU_Computing_SDK && make clean && make -j6 all"
end
