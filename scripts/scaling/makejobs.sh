#!/bin/bash


for i in {145..256}; do
    cd "$i"/
#    rm *.log
#    rm *.out
    echo "#!/bin/bash" > job-hydro.slm
    echo '#SBATCH -n '"$i"' -t 00:05:00' >> job-hydro.slm
    echo '#SBATCH -p zbox'  >> job-hydro.slm
    echo "#SBATCH --job-name='hydro""$i""'" >> job-hydro.slm
    echo 'export DATE=`date +%F_%Hh%M`' >> job-hydro.slm
    echo "srun -n ""$i"' ./hydro_mpi mladen-IO.nml > run$DATE.log' >> job-hydro.slm
    cd ..
done

