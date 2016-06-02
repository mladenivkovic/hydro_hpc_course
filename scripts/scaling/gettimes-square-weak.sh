!#/bin/bash

wd=$PWD
printf "%s\t%s\t%s\n" "#ncpu" "cpu-time" "     real-time" > $wd/times.dat

for i in 1 2 3 4 5 6 7 8 ; do
    square=$(( $i * $i ))

    cd $square
    if [ -f run*.log ]; then
        echo "reading from " $square
        cputime=`tail -n 2 run*.log | awk 'NR==1{print $5}'`
        realtime=`tail -n 1 run*.log | awk '{print $5}'`
        printf "%s\t%s\t%s\n" "$square" "$cputime" "$realtime" >> $wd/times.dat
    else
        echo $square": no runlog found."
    fi
    cd ..

done
