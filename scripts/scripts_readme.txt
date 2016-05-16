On these scripts and how to use them:


- ffmpeg_makemovie
    creates a movie out of png images. Not intended to be used on 
    its own, is called by the script makemovie.
    If used on its own, it makes a movie out of all .png files in 
    the directory it is called from. 
    It may be given a command line argument for the ouput filename
    of the movie. If not given, default is ../movie.mp4

- fortranfile.py
    A python class that enables you to read the fortran output.

- hydropic:
    creates a .pdf of an HYDRO output file.
    use: hydropic.py output_00XXXXXX

- hydropic_movie
    used by makemovie script to create a movie of all outputfiles 
    in a directory. Not intended to be used on its own, but can 
    be.

- hydropic_movie_parallel
    used by the script makemovie_parallel to create a .png file 
    from all output files of a parallel run. Can be used on its
    own:
    hydropic_movie_parallel <nproc> <outputfiles>
    <nproc> : number of processors used for the hydro code run
    <ouputfiles> : all outputfiles from all processors for a 
    single snapshot, e.g. output_00038.00001 output_00038.00002
    output_00038.00003 output_00038.00004 (if nproc = 4)

- hydropic_movie_parallel_barlimits
    Same as hydropic_movie_parallel, but will take two more cmd
    line args: the lower and upper limit for the colorbar of the
    plots, so all the .png files will have the same scale.
    Will be used by makemovie_parallel_barlimits, can be used on
    its own:
    hydropic_movie_parallel_barlimits <nproc> <lowerlimit> 
    <upperlimit> <outputfiles>

- makemovie
    makes movie out of all outputfiles in a directory.
    puts the png output in subdirectory "picoutput".

- makemovie_parallel
    makes movie out of all outputfiles in a directory that have 
    been made by a parallel run. 
    It puts the .png output in subdirectory "picoutput".
    Usage: makemovie_parallel <nproc>
    <nproc> : number of processors used for the simulation run

- makemovie_parallel_barlimits
    Same as makemovie_parallel, but will take two more cmd
    line args: the lower and upper limit for the colorbar of the
    plots, so all the .png files will have the same scale.
    Usage:
    makemovie_parallel_barlimits <nproc> <lowerlimit> <upperlimit> 
