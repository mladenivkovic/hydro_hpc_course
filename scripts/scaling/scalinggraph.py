#!/home/ics/volker/Anaconda/bin/python
# ^ for pyhton on zbox


from os import getcwd
from sys import argv #command line arguments
import matplotlib 
matplotlib.use('Agg') #don't show anything unless I ask you to. So no need to get graphical all over ssh.
import subprocess
import numpy as np
import matplotlib.pyplot as plt




outputfilename = "scaling_plot"
title='Hydro Code Scaling'
workdir= str(getcwd())



def get_times(filename):

    print " Extracting data from file"

    data=np.loadtxt(filename)
    nproc=data[:,0]
    #cputime=data[:,1]
    time=data[:,2]

    return nproc,time




########################################################################
########################################################################
########################################################################
########################################################################


if __name__ == "__main__":

    print "Creating figure"

    nls, tls= get_times('strong-linear.dat')
    nlw, tlw= get_times('weak-linear.dat')
    nss, tss= get_times('strong-square.dat')
    nsw, tsw= get_times('weak-square.dat')

    stls=tls[0]
    stlw=tlw[0]
    stss=tss[0]
    stsw=tsw[0]
   
    # creating empty figure with 3 subplots
    fig = plt.figure(facecolor='white')#, figsize=(10,4))
    fig.suptitle(title, family='serif', size=16) 
    #ax1.set_xbound(lower=0.0,upper=1.0)
    #plt.tight_layout()

    lw=[]
    sw=[]
    for i in range(0,len(nlw)):
        lw.append(stlw/(tlw[i]*nlw[i]))

    for j in range(0,len(nsw)):
        sw.append(stsw/(tsw[j]*nsw[j]))

    ax1 = plt.subplot(121)#, aspect='equal')
    ax1.set_xlim([0.0, nls[-1]+1])
    ax1.plot(nlw, lw, 'r-', linewidth=0.1, label='linear domain')
    ax1.plot(nlw, lw, 'ro', markersize=2.5, markeredgecolor='r')
    ax1.plot(nsw, sw, 'b-', linewidth=0.1, label='square domain')
    ax1.plot(nsw, sw, 'bo', markersize=2.5, markeredgecolor='b')
    ax1.grid(color='lightgrey',linestyle='solid', linewidth=0.1 )
    ax1.legend(loc=0, prop={'size':9,'family':'serif'})
    ax1.set_title("Weak Scaling", size=13, family='serif')
    ax1.set_xlabel("P", family='serif')
    ax1.set_ylabel(r"$t_{mono}$/$(P \cdot t_{P})$", family='serif')

    ax2 = plt.subplot(122)#, aspect='equal')
    ax2.set_xlim([0.0, nls[-1]+1])
    ax2.plot(nls, stls/tls, 'r-', linewidth=0.1, label='linear domain')
    ax2.plot(nls, stls/tls, 'ro', markersize=2.5, markeredgecolor='r')
    ax2.plot(nss, stss/tss, 'b-', linewidth=0.1, label='square domain')
    ax2.plot(nss, stss/tss, 'bo', markersize=2.5, markeredgecolor='b')
    ax2.grid(color='lightgrey',linestyle='solid', linewidth=0.1 )
    ax2.legend(loc=0, prop={'size':9,'family':'serif'})
    ax2.set_title("Strong Scaling", size=13, family='serif')
    ax2.set_xlabel("P", family='serif')
    ax2.set_ylabel(r"$t_{mono}$/$t_{P}$", family='serif')

    plt.subplots_adjust(left=0.1, right=0.95, top=0.9, bottom=0.1,wspace=0.3)
    
    print "Figure created"

#    plt.subplot_tool()
#    plt.show() 
    # saving figure
    fig_path = workdir+'/'+outputfilename+'.pdf'
    print "saving figure as"+fig_path
    plt.savefig(fig_path, format='pdf', facecolor=fig.get_facecolor(), transparent=False, dpi=150)
    plt.close()

    print "done", outputfilename+".png"
