#!/bin/bash


for i in 1 9 16 25 36 49 64 81 100 121 144 169 196 225 256 289 324 361 484 729 900; do
    mkdir $i
    cd "$i"/
    rm *.log
    rm *.out
    rm -r hydro_output
    echo "#!/bin/bash" > job-hydro.slm
    echo '#SBATCH -n '"$i"' -t 00:01:00' >> job-hydro.slm
    echo "#SBATCH --job-name='hydro_sw""$i""'" >> job-hydro.slm
    echo "#SBATCH --ntasks-per-core=1" >> job-hydro.slm
    echo 'export DATE=`date +%F_%Hh%M`' >> job-hydro.slm
    echo "srun -n ""$i"' ./hydro_mpi mladen_IO.nml > run$DATE.log' >> job-hydro.slm
    
    cp ~/hydro/HYDRO/F90/MPI/Src/hydro_mpi .

    size=`echo "scale=3; sqrt(""$i"")*200" | bc`
    size=`echo $size | awk '{print int($1+0.5)}'` #runden
    echo "&RUN" >mladen_IO.nml
    echo "nstepmax=100" >>mladen_IO.nml
    echo "tend=999999.0" >>mladen_IO.nml
    echo "noutput=1001" >>mladen_IO.nml
    echo "on_output=.false." >>mladen_IO.nml
    echo "/" >>mladen_IO.nml
    echo "" >>mladen_IO.nml
    echo "&MESH" >>mladen_IO.nml
    echo "nx=""$size" >>mladen_IO.nml
    echo "ny=""$size" >>mladen_IO.nml
    echo "dx=0.0001" >>mladen_IO.nml
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

