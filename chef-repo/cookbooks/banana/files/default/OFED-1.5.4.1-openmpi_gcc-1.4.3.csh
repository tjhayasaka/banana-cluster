# NOTE: This is an automatically-generated file!  (generated by the
# Open MPI RPM).  Any changes made here will be lost if the RPM is
# uninstalled or upgraded.

# path
if ("" == "`echo $path | grep /usr/mpi/gcc/openmpi-1.4.3/bin`") then
    set path=(/usr/mpi/gcc/openmpi-1.4.3/bin $path)
endif

# LD_LIBRARY_PATH
if ("1" == "$?LD_LIBRARY_PATH") then
    if ("$LD_LIBRARY_PATH" !~ */usr/mpi/gcc/openmpi-1.4.3/lib64*) then
        setenv LD_LIBRARY_PATH /usr/mpi/gcc/openmpi-1.4.3/lib64:${LD_LIBRARY_PATH}
    endif
else
    setenv LD_LIBRARY_PATH /usr/mpi/gcc/openmpi-1.4.3/lib64
endif

# MANPATH
if ("1" == "$?MANPATH") then
    if ("$MANPATH" !~ */usr/mpi/gcc/openmpi-1.4.3/share/man*) then
        setenv MANPATH /usr/mpi/gcc/openmpi-1.4.3/share/man:${MANPATH}
    endif
else
    setenv MANPATH /usr/mpi/gcc/openmpi-1.4.3/share/man:
endif
