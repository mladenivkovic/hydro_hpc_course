#!/bin/bash


for i in {145..256}; do
    cd "$i"/
    sbatch job-hydro.slm
    cd ..
done

