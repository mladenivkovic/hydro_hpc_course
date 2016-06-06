#!/usr/bin/python

#!/home/ics/volker/Anaconda/bin/python
# ^ for pyhton on zbox


from os import getcwd
from sys import argv #command line arguments
import matplotlib 
matplotlib.use('Agg') #don't show anything unless I ask you to. So no need to get graphical all over ssh.
import subprocess
import numpy as np
import matplotlib.pyplot as plt




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

    print "Creating figures"

    nls, tls= get_times('linear-strong.dat')
    nlw, tlw= get_times('linear-weak.dat')
    nss, tss= get_times('square-strong.dat')
    nsw, tsw= get_times('square-weak.dat')

    mtls=tls[0] # mono time linear strong
    mtlw=tlw[0] # mono time linear weak
    mtss=tss[0] # mono time square strong
    mtsw=tsw[0] # mono time square weak
 




###########################
#### WEAK SCALING
###########################

    fig1 = plt.figure(1, facecolor='white')#, figsize=(10,4))
    # enables switching between figures
    fig1.suptitle('Weak Scaling', family='serif', size=16) 

    #calculating weak scaling points
    lw=[] # linear weak
    sw=[] # square weak
    for i in range(0,len(nlw)):
        lw.append((tlw[i]/nlw[i])*mtlw)

    for j in range(0,len(nsw)):
        sw.append((tsw[j]/nsw[j])*mtsw)

    ax1 = plt.subplot(121)#, aspect='equal')
    ax1.set_xlim([0.0, nlw[-1]+1])
    ax1.plot(nlw, tlw, 'r-', linewidth=0.1, label='linear domain')
    ax1.plot(nlw, tlw, 'ro', markersize=2.5, markeredgecolor='r')
    ax1.plot(nsw, tsw, 'b-', linewidth=0.1, label='square domain')
    ax1.plot(nsw, tsw, 'bo', markersize=2.5, markeredgecolor='b')
    ax1.grid(color='lightgrey',linestyle='solid', linewidth=0.1 )
    ax1.legend(loc=0, prop={'size':9,'family':'serif'})
    ax1.set_title("Computation Time", size=13, family='serif')
    ax1.set_xlabel("P", family='serif')
    ax1.set_ylabel(r"$t_{mono}$/$(P \cdot t_{P})$", family='serif')


    ax2 = plt.subplot(122)#, aspect='equal')
    ax2.set_xlim([0.0, nlw[-1]+1])
    ax2.semilogy(nlw, lw, 'r-', linewidth=0.1, label='linear domain')
    ax2.semilogy(nlw, lw, 'ro', markersize=2.5, markeredgecolor='r')
    ax2.semilogy(nsw, sw, 'b-', linewidth=0.1, label='square domain')
    ax2.semilogy(nsw, sw, 'bo', markersize=2.5, markeredgecolor='b')
    ax2.grid(color='lightgrey',linestyle='solid', linewidth=0.1 )
    ax2.legend(loc=0, prop={'size':9,'family':'serif'})
    ax2.set_title("Speedup", size=13, family='serif')
    ax2.set_xlabel("P", family='serif')
    ax2.set_ylabel(r"$t_{mono}$/$t_{P}$", family='serif')



    plt.subplots_adjust(left=0.1, right=0.95, top=0.9, bottom=0.1,wspace=0.3)

    fig_path = workdir+'/'+'weak_scaling'+'.pdf'
    print "saving figure as"+fig_path
    plt.savefig(fig_path, format='pdf', facecolor=fig1.get_facecolor(), transparent=False, dpi=150)
    plt.close()








###########################
#### STRONG SCALING
###########################




    fig2 = plt.figure(2, facecolor='white')
    
    fig1.suptitle('Strong Scaling', family='serif', size=16) 
    
    
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
    ax2.plot(nls, mtls/tls, 'r-', linewidth=0.1, label='linear domain')
    ax2.plot(nls, mtls/tls, 'ro', markersize=2.5, markeredgecolor='r')
    ax2.plot(nss, mtss/tss, 'b-', linewidth=0.1, label='square domain')
    ax2.plot(nss, mtss/tss, 'bo', markersize=2.5, markeredgecolor='b')
    ax2.grid(color='lightgrey',linestyle='solid', linewidth=0.1 )
    ax2.legend(loc=0, prop={'size':9,'family':'serif'})
    ax2.set_title("Strong Scaling", size=13, family='serif')
    ax2.set_xlabel("P", family='serif')
    ax2.set_ylabel(r"$t_{mono}$/$t_{P}$", family='serif')

    plt.subplots_adjust(left=0.1, right=0.95, top=0.9, bottom=0.1,wspace=0.3)
    

#    plt.subplot_tool()
#    plt.show() 
    # saving figures
    #fig_path = workdir+'/'+outputfilename+'.pdf'
    fig_path = workdir+'/'+'strong_scaling'+'.pdf'
    print "saving figure as"+fig_path
    plt.savefig(fig_path, format='pdf', facecolor=fig2.get_facecolor(), transparent=False, dpi=150)




    print "done"
