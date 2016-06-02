#!/bin/bash

wd=$PWD
printf "%s\t%s\t%s\n" "#ncpu" "cpu-time" "     real-time" > $wd/squaretimes.dat
printf "%s\t%s\t%s\n" "#ncpu" "cpu-time" "     real-time" > $wd/lineartimes.dat

for i in {1..256}; do

    cd $i
    if [ -f run*.log ]; then

        #echo "reading from " $i
        
        nprocx=`head run* | awk 'NR==8 {print $4}'`
        nprocy=`head run* | awk 'NR==8 {print $5}'`
       
        difference=$(($nprocx - $nprocy))
        #echo "difference:" $difference
        #echo "x" $nprocx "y" $nprocy

        if [ "$difference" -lt 0 ]; then
            difference=$(( $difference*(-1) ))
        fi

        if [ "$difference" -lt 1 ]; then
            echo "square: $i"
            cputime=`tail -n 2 run*.log | awk 'NR==1{print $5}'`
            realtime=`tail -n 1 run*.log | awk '{print $5}'`
            printf "%s\t%s\t%s\n" "$i" "$cputime" "$realtime" >> $wd/squaretimes.dat
        fi

        if [ "$nprocx" == 1 ] || [ "$nprocy" == 1 ]; then
            echo "linear:" $i
            cputime=`tail -n 2 run*.log | awk 'NR==1{print $5}'`
            realtime=`tail -n 1 run*.log | awk '{print $5}'`
            printf "%s\t%s\t%s\n" "$i" "$cputime" "$realtime" >> $wd/lineartimes.dat
        fi

    else
        echo $i": no runlog found."
    fi
    cd ..

done
