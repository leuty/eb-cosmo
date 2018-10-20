# Building Cosmo with EB and the build script

This is temporary tutorial to allow people to build their own version of crCLIM COSMO-pompa.
The steps are only describing on how to compile the model on **DAINT** with the **CRAY** compiler.

We provide a TL;DR for the impatient.
But it's recommended that you read the full documentation.
As compiling the model is very slow on Daint, you may trigger the compilation with the TL;DR section and read the full documentation while it's compiling. 
If the TL;DR doesn't work, read the full documentation.

## TL;DR

For this TL;DR we assume that we're working from the hypotetic "scratch" directory of the user `username`:
```
/scratch/username/
``` 
but the following instructions apply for any wokring directory.
We also assume that everything is executed in the **same** terminal.

Clone this repository:
```
git clone git@github.com:PallasKat/eb-cosmo.git
cd eb-cosmo
```
and go in it's directory:
```
cd eb-cosmo
```

Use the new dirver script to build the libraries needed to build Cosmo:
```
$ ./build_crclim_libs.sh -h
Usage: build_crclim_libs.sh -p project -t target -i path [-z]
```
where `-p` is the project (or setup): `crclim` or `cordex`, the `-t` is the target: `cpu` or `gpu`, and `-i` the module install path.
For example installing Stella and the Dycore with the Cordex setup for CPU in `/scratch/username/install/`:
```
$ ./build_crclim_libs.sh -p cordex -t cpu -i /scratch/username/install/
```
and note that the install directory must exist **before** executing the script.
At the end the script output variables to export and module to load:
```
export EASYBUILD_PREFIX=/scratch/username/install/
export EASYBUILD_BUILDPATH=/tmp/username/easybuild
module load daint-gpu
module load EasyBuild-custom
```
and execute them in your current environment (i.e. terminal).

Change to the directory containing the Cosmo source you want to compile.
For example, we assume that the Cosmo we want to compile is here:
```
cd /scratch/username/cosmo-pompa/cosmo
```
and we start by executing the Cosmo builds script to trigger the environement fetching:
```
test/jenkins/build.sh -h
```
and replace the Daint environment by the one provided by this repository:
```
cp /scratch/username/eb-cosmo/env/env.daint.sh test/jenkins/env/
```
and the `option.lib` files for both architectures:
```
cp /scratch/username/eb-cosmo/env/Options.lib.cpu .
cp /scratch/username/eb-cosmo/env/Options.lib.gpu .
```
As we previously installed the Cordex DyCore for CPU, we load the corresponding module:  
```
module load DYCORE_CRCLIM_CPU/cordex-CrayGNU-18.08-double
```
and we run the Cosmo build script:
```
test/jenkins/./build.sh -z -c cray -t gpu -x $EBVERSIONDYCORE_CRCLIM_GPU
```
et voilà! After a waiting time close to ~1h to 1h30' you have a working Cosmo executable.

## Building Stella and the Dycore

Clone this repository.
You can see that there are several easybuild (EB) config files.
Two are for STELLA:
```
STELLA_CORDEX-CrayGNU-18.08-double.eb
STELLA_CRCLIM-CrayGNU-18.08-double.eb
```
and four for the C++ DyCore:
```
DYCORE_CORDEX_CPU-CrayGNU-18.08-double.eb
DYCORE_CORDEX_GPU-CrayGNU-18.08-double.eb
DYCORE_CRCLIM_CPU-CrayGNU-18.08-double.eb
DYCORE_CRCLIM_GPU-CrayGNU-18.08-double.eb
```
and respectively contain the information to build Stella and the DyCore with EB.
As you can deduce from the filenames, some are for the crCLIM or Cordex setup, or to target the CPU or GPU.
The difference compared to the classic build scripts is that EB is going to make Stella and the DyCore available as modules on Daint. So once it's install you'll have to load the needed DyCore depending on the configuration you need.

You don't have to invoke EB yourself, you should only use the provided script `build_crclim_libs.sh`. 
This script drives the call to EB to build the Stella and DyCore libraries and make them available as modules.
Its goal is to minimise the steps the domain scientist need to do.

To invoke the script you should provide at least the project (i.e. crclim or cordex) and the targeted architecture (i.e. cpu or gpu).
There is a command line help that decribes what you can pass to the script:
```
$ ./build_crclim_libs.sh -h
Usage: build_crclim_libs.sh -p project -t target [-z]

Arguments:
-h           show this help message and exit
-p project   build project: crclim or cordex
-t target    build target: cpu or gpu
-z           clean any existing repository, reclone it, and create new source archive
```
The script fetch (clone) the `crclim` branch of the `stella` and the `cosmo-pompa` repositories from the `C2SM-RCM` organisation.
This is the default behavior. 
To change it, you need to modify the script (see "Advanced usage of the script").
Once the sources are fetch, it creates an archive of the sources (a `tar.gz` file).
This is because we don't have release yet and EB is expecting an archive from a release or a file list (but this is too "complicated" to provide).
The esiest way to hack it was to create the "release" (i.e. the archive) on the fly from the cloned repositories. 

Then EB is invoked to build Stella and the C++ DyCore.
The correct version is selected according the values provided with the `-t` and `-p` flags.
For example with `-p cordex` we ensure that Stella is built with `KFLAT=8` and `KLEVEL=40`.
When started the script is print the requested configuration:
```
$ ./build_crclim_libs.sh -t gpu -p crclim
===========================================================
Compiling STELLA and the C++ DyCore as modules
===========================================================
Date             : sam oct 20 13:05:46 CEST 2018
Machine          : daint102
User             : charpill
Architecture
   CPU           : OFF
   GPU           : ON
Project
   crCRLIM       : ON
   Cordex        : OFF
Cleanup          : OFF
===========================================================
```
Both libraries (Stella and the DyCore) will be available through modules loading.
Before being able use them you need to export variables and import modules.
At end of the compilation, the script is writing what you should export and load:
```
================================================================
EXECUTE THE FOLLOWING COMMANDS IN YOUR TERMINAL BEFORE
INSTALLING COSMO
================================================================
export EASYBUILD_PREFIX=/path/to/install/
export EASYBUILD_BUILDPATH=/tmp/username/easybuild
module load daint-gpu
module load EasyBuild-custom
================================================================
```
copy and past them in your terminal before trying to load the Stella and Dycore modules.

The `-z` flag is used to clean up the repository.
As you may need to refresh it (or reclone it) the cleanup flag ensure the repository is DELETED before cloning it.
Otherwise you end up with an error of the kind:
```
fatal: destination path 'cosmo-pompa' already exists and is not an empty directory.
```
and nothing is cloned.

## Building COSMO

Once the needed modules are loaded:
```
export EASYBUILD_PREFIX=/path/to/install/
export EASYBUILD_BUILDPATH=/tmp/username/easybuild
module load daint-gpu
module load EasyBuild-custom
```
you can see that the installed libraries are available:
```
------------ /path/to/install//modules/all ```------------
DYCORE_CRCLIM_GPU/crclim-CrayGNU-18.08-double 
Serialbox/2.4.1-CrayGNU-18.08                 
libgrib1_crclim/a1e4271-CrayCCE-18.08 
STELLA_CRCLIM/crclim-CrayGNU-18.08-double     
grib_api/1.13.1-CrayCCE-18.08
```
where here we have access to a DyCore with the crCLIM setup compiled for GPU (`DYCORE_CRCLIM_GPU`).
To use it, load it:
```
module load DYCORE_CRCLIM_GPU/crclim-CrayGNU-18.08-double
```
which export a variable (among others) `EBROOTDYCORE_CRCLIM_GPU`:
```
$ echo $EBROOTDYCORE_CRCLIM_GPU
/path/to/install/software/DYCORE_CRCLIM_GPU/crclim-CrayGNU-18.08-double
```
The variable name will change according the setup you decided to build.
If you're unsure of the variable name, you can request details of the module with:
```
$ module show DYCORE_CRCLIM_GPU/crclim-CrayGNU-18.08-double
-------------------------------------------------------------------
/path/to/install//modules/all/DYCORE_CRCLIM_GPU/crclim-CrayGNU-18.08-double:

module-whatis	 Description: COSMO Pompa Dynamical core for GPU (CRCLIM) 
module-whatis	 Homepage: https://github.com/C2SM-RCM/cosmo-pompa/tree/master/dycore (-b crclim) 
conflict	 DYCORE_CRCLIM_GPU 
prepend-path	 LD_LIBRARY_PATH /path/to/install/software/DYCORE_CRCLIM_GPU/crclim-CrayGNU-18.08-double/lib 
prepend-path	 LIBRARY_PATH /path/to/install/software/DYCORE_CRCLIM_GPU/crclim-CrayGNU-18.08-double/lib 
prepend-path	 PATH /path/to/install/software/DYCORE_CRCLIM_GPU/crclim-CrayGNU-18.08-double/bin 
setenv		 EBROOTDYCORE_CRCLIM_GPU /path/to/install/software/DYCORE_CRCLIM_GPU/crclim-CrayGNU-18.08-double 
setenv		 EBVERSIONDYCORE_CRCLIM_GPU crclim 
setenv		 EBDEVELDYCORE_CRCLIM_GPU /scratch/snx1600/charpill/post-update/install/software/DYCORE_CRCLIM_GPU/crclim-CrayGNU-18.08-double/easybuild/DYCORE_CRCLIM_GPU-crclim-CrayGNU-18.08-double-easybuild-devel 
```
where you see the available environement variables.
In our case we're interested by the one pointing to the installed DyCore.

Once this is done, we can almost build Cosmo the "classical" way, that is to say with build script.
you can almost start to build Cosmo, you just need to replace the `env.daint.sh` as the one in the buildenv is not adapted anymore to build the model on Daint.
Start by triggering environment fetching by calling:
```
cd cosmo-pompa/cosmo
test/jenkins/./build.sh
```
then replace the Daint environment:
```
cp env.daint.sh test/jenkins/env/
```
and execute the build script as usual:
```
test/jenkins/./build.sh -z -c cray -t gpu -x $EBVERSIONDYCORE_CRCLIM_GPU
```

## Troubleshooting

If you encouter any issue with any of the output libraries (grib, netcdf, serialbox, ...), start by building the libraries:
```
eb grib_api-1.13.1-CrayCCE-18.08.eb -r
eb libgrib1_crclim-a1e4271-CrayCCE-18.08.eb -r
```
then apply the folowing modification to `Options.lib.gpu`:
```
# Grib1 library
GRIBDWDL = -L${EBROOTLIBGRIB1_CRCLIM} -lgrib1_cray
GRIBDWDI =

# Grib-API library
GRIBAPIL = -L${EBROOTGRIB_API}/lib -lgrib_api_f90 -lgrib_api -L${EBROOTJASPER}/lib -ljasper
GRIBAPII = -I${EBROOTGRIB_API}/include

# NetCDF library
NETCDFL  = -L/opt/cray/pe/lib64
NETCDFI  = -I/opt/cray/pe/netcdf/4.6.1.2/CRAY/8.6/include

# Serialization library
SERIALBOX  = ${EBROOTSERIALBOX}
SERIALBOXL = -L${EBROOTSERIALBOX}/lib
```

WARNING: Found one or more non-allowed loaded (EasyBuild-generated) modules in current environment:
* cURL/.7.47.0
* expat/.2.1.0
* zlib/.1.2.8
* libxml2/.2.9.3
* ncurses/.6.0
* gettext/.0.19.7
* Perl/5.22.1-bare
* git/.2.13.1

This is not recommended since it may affect the installation procedure(s) performed by EasyBuild.

## Advanced usage of the script

