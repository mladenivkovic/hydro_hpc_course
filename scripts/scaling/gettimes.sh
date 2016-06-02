!#/bin/bash

wd=$PWD
printf "%s\t%s\t%s\n" "#ncpu" "cpu-time" "     real-time" > $wd/times.dat

for i in 1 2 4 8 16 32 128 256; do

    cd $i
    if [ -f run*.log ]; then
        echo "reading from " $i
        cputime=`tail -n 2 run*.log | awk 'NR==1{print $5}'`
        realtime=`tail -n 1 run*.log | awk '{print $5}'`
        printf "%s\t%s\t%s\n" "$i" "$cputime" "$realtime" >> $wd/times.dat
    else
        echo $i": no runlog found."
    fi
    cd ..

done
