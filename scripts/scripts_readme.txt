On these scripts and how to use them:


- ffmpeg_makemovie
    creates a movie out of png images. Not intended to be used
    on its own, is called by the script makemovie.

- fortranfile.py
    A python class that enables you to read the fortran output.

- getmaxden
    DOES NOT WORK (yet).
    A script to find the maximal density of the simulation run
    for the colorbar; so that the colorbar is the same for all
    images.

- hydropic:
    creates a .pdf of an HYDRO output file.
    use: hydropic.py output_00XXXXXX

- hydropic_movie
    used by makemovie script to create a movie of all outputfiles in a directory. Not intended to be used on its own, but can be.

- makemovie
    makes movie out of all outputfiles in a directory.
    puts the png output in subdirectory "picoutput".
