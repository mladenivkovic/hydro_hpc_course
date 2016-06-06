#!/bin/bash


#for i in 1 9 16 25 36 49 64 81 100 121 144 169 196 225 256 289 324; do
for i in 361; do
    mkdir $i
    cd "$i"/
    rm *.log 2>/dev/null
    rm -r hydro_output 2>/dev/null
    rm *.out 2>/dev/null
    echo "#!/bin/bash" > job-hydro.slm
    echo '#SBATCH -n '"$i"' -t 00:45:00' >> job-hydro.slm
    echo "#SBATCH --job-name='hydro_ss""$i""'" >> job-hydro.slm
    echo "#SBATCH --ntasks-per-core=1" >> job-hydro.slm
    echo 'export DATE=`date +%F_%Hh%M`' >> job-hydro.slm
    echo "srun -n ""$i"' ./hydro_mpi mladen_IO.nml > run$DATE.log' >> job-hydro.slm
    
    cp ~/hydro/HYDRO/F90/MPI/Src/hydro_mpi .


    echo "&RUN" >mladen_IO.nml
    echo "nstepmax=100" >>mladen_IO.nml
    echo "tend=99999999.0" >>mladen_IO.nml
    echo "noutput=1001" >>mladen_IO.nml
    echo "on_output=.false." >>mladen_IO.nml
    echo "/" >>mladen_IO.nml
    echo "" >>mladen_IO.nml
    echo "&MESH" >>mladen_IO.nml
    echo "nx=16200" >>mladen_IO.nml
    echo "ny=16200" >>mladen_IO.nml
    echo "dx=0.001" >>mladen_IO.nml
    echo "boundary_left=1" >>mladen_IO.nml
    echo "boundary_right=1" >>mladen_IO.nml
    echo "boundary_down=1" >>mladen_IO.nml
    echo "boundary_up=1" >>mladen_IO.nml
    echo "idimbloc=21" >>mladen_IO.nml
    echo "jdimbloc=21" >>mladen_IO.nml
    echo "/" >>mladen_IO.nml
    echo "" >>mladen_IO.nml
    echo "&HYDRO" >>mladen_IO.nml
    echo "courant_factor=0.8" >>mladen_IO.nml
    echo "niter_riemann=10" >>mladen_IO.nml
    echo "/" >>mladen_IO.nml
    cd ..
done

