#!/bin/bash


for i in 1 4 9 16 25 36 49 64 81 100 121 144 169 196 225 256 ; do
    cd "$i"/
    sbatch job-hydro.slm
    cd ..
done

