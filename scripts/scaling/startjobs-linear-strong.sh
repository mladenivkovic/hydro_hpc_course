#!/bin/bash


for i in {1..360}; do
    if [ -d $i ] ; then
    cd "$i"/
    sbatch job-hydro.slm
    cd ..
    fi
done

