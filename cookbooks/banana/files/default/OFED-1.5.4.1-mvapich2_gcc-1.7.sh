if ! echo ${PATH} | grep -q /usr/mpi/gcc/mvapich2-1.7/bin ; then
    PATH=/usr/mpi/gcc/mvapich2-1.7/bin:${PATH}
fi

if ! echo ${LD_LIBRARY_PATH} | grep -q /usr/mpi/gcc/mvapich2-1.7/lib ; then
    export LD_LIBRARY_PATH=/usr/mpi/gcc/mvapich2-1.7/lib:${LD_LIBRARY_PATH} 
fi

if ! echo ${MANPATH} | grep -q /usr/mpi/gcc/mvapich2-1.7/man ; then
    MANPATH=/usr/mpi/gcc/mvapich2-1.7/man:${MANPATH}
fi
