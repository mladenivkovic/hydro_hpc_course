import fortranfile
import numpy
from matplotlib import pyplot
from sys import argv # command line arguments

map_file = str(argv[1])
print map_file
#map_file = '/scratch/daint/biernack/hpc1b/jet/output_00010.00000'

# read image data
f = fortranfile.FortranFile(map_file)
[t, gamma] = f.readReals()
[nx,ny,nvar,nstep] = f.readInts()
dat = f.readReals()
f.close()

dat = numpy.array(dat)
dat = dat.reshape(nvar,ny,nx)

fig = pyplot.figure()
ax = fig.add_subplot(1,1,1)

ax.imshow(dat[0,:,:],interpolation='nearest')

#pyplot.show()
