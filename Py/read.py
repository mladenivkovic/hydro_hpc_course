import fortranfile
import numpy
from matplotlib import pyplot

map_file = '/scratch/daint/biernack/hpc1b/jet/output_00010.00000'

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


pyplot.show()
