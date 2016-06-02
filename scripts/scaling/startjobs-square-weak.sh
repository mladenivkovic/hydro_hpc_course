#!/bin/bash


for i in 1 2 3 4 5 6 7 8; do
    square=$(( $i * $i ))
    cd "$square"/
    sbatch job-hydro.slm
    cd ..
done

