# How to build COSMO in a post Daint update world

This is temporary tutorial to allow people to build their own version of crCLIM COSMO-pompa.
The steps are only describing on how to compile the model on **DAINT** with the **CRAY** compiler.

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
export EASYBUILD_PREFIX=/scratch/snx1600/charpill/post-update/install/
export EASYBUILD_BUILDPATH=/tmp/charpill/easybuild
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



## Advanced usage of the script


## Steps before building COSMO

As we're going to use EasyBuild (EB), you should export the following variable:
```
export EASYBUILD_PREFIX=/path/to/your/install/
export EASYBUILD_BUILDPATH=/tmp/$USER/easybuild
```
then load the needed modules:
```
module load daint-gpu
module load EasyBuild-custom
```
then, if needed, build the following libraries with EB:
```
eb grib_api-1.13.1-CrayCCE-18.08.eb -r
eb libgrib1_crclim-a1e4271-CrayCCE-18.08.eb -r
```
Note that the `-r` option resolves dependencies automatically (e.g. Boost, Cuda, ...).

Now EB is pointing to the repository with the `EASYBUILD_PREFIX` variable and you can see the install modules with:
```
module avail
```
Please note that once the modules have been built they're always available.
But after a fresh login you should forget to do:
```
module use /path/to/your/install/modules/all
```
which is the path that has been used when exporting `EASYBUILD_PREFIX` (i.e. `/path/to/your/install/`).

## Preparing Cosmo build environment

To compile COSMO with the previously built modules you need to change a bit the environment.
As this tutorial is only explaining how to compile a GPU executable with Cray, you have to adapt `Options.lib.gpu`, ~`Options.daint.cray.gpu`~, and `env.daint.sh`.

Modification in `Options.lib.gpu`:
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

Modification in `Options.daint.cray.gpu`:
```
NOTHING SHOULD BE MODIFIED
```

Several modifications in `env.daint.sh`.


## Building COSMO

Load the needed modules:
```
module use module use /path/to/your/install/modules/all
module load daint-gpu
module load grib_api/1.13.1-CrayCCE-18.08 libgrib1_crclim/a1e4271-CrayCCE-18.08
module remove cudatoolkit craype-accel-nvidia60 cray-libsci_acc cray-netcdf
```
where `/path/to/your/install/` is the path that has been used when exporting EASYBUILD_PREFIX.
Then execute the build script as usual:
```
test/jenkins/./build.sh -z -c cray -t gpu -x /path/to/dycore/install
```
