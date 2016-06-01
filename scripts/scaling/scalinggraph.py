#!/home/ics/volker/Anaconda/bin/python
# ^ for pyhton on zbox


from os import getcwd
from sys import argv #command line arguments
import matplotlib 
matplotlib.use('Agg') #don't show anything unless I ask you to. So no need to get graphical all over ssh.
import subprocess
import numpy as np
import matplotlib.pyplot as plt




outputfilename = "weak_scaling_plot"
title='Weak Scaling'
workdir= str(getcwd())



def extract_ascii_times(filename):

    print " Extracting data from file"

    data=np.loadtxt(filename)
    nproc=data[:,0]
    cputime=data[:,1]
    elapsedtime=data[:,2]

    return nproc,cputime,elapsedtime




########################################################################
########################################################################
########################################################################
########################################################################


if __name__ == "__main__":

    print "Creating figure"

    nproc, cputime,elapsedtime = extract_ascii_times('times.dat')

    
    # creating empty figure with 3 subplots
    fig = plt.figure(facecolor='white', figsize=(10,4))
    fig.suptitle(title, family='serif', size=20) 
    ax1 = fig.add_subplot(221)#, aspect='equal', clip_on=True)
    #ax1.set_xbound(lower=0.0,upper=1.0)
    #plt.tight_layout()

    serialtime_cpu=cputime[0]
    serialtime_elapsed=elapsedtime[0]
    ax1.set_xlim([0.0, nproc[len(nproc)-1]])
    ax1.grid(color='lightgrey',linestyle='solid', linewidth=0.1 )
    ax1.plot(nproc, serialtime_cpu/cputime, linewidth=0.1)
    ax1.plot(nproc, serialtime_cpu/cputime, 'ro', markersize=1.5, markeredgecolor='r')
    ax1.set_title("CPU time")


    
    ax2 = fig.add_subplot(222)#, aspect='equal')
    ax2.set_xlim([0.0, nproc[len(nproc)-1]])
    ax2.grid(color='lightgrey',linestyle='solid', linewidth=0.1 )
    ax2.plot(nproc, serialtime_elapsed/elapsedtime, linewidth=0.1)
    ax2.plot(nproc, serialtime_cpu/cputime, 'ro', markersize=1.5, markeredgecolor='r')
    ax2.set_title("elapsed time")
    print "Figure created"
    
    
    # saving figure
    fig_path = workdir+'/'+outputfilename+'.pdf'
    print "saving figure as"+fig_path
    plt.savefig(fig_path, format='pdf', facecolor=fig.get_facecolor(), transparent=False, dpi=150)
    plt.close()

    print "done", outputfilename+".png"
