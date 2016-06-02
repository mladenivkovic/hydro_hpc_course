#!/bin/bash


for i in 1 2 4 8 16 32 64 128 256; do
    cd "$i"/
    sbatch job-hydro.slm
    cd ..
done

