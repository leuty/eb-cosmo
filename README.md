# Building Cosmo with EB and the build script

This is a temporary tutorial to allow people to build their own version of crCLIM COSMO-pompa.
The steps are only describing on how to compile the model on **DAINT** with the **CRAY** compiler.

We provide a TL;DR for the impatient.
But it's recommended that you read the full documentation.
As compiling the model is very slow on Daint (it takes on average 50-60 minutes!), you may trigger the compilation with the instruction in the TL;DR section and read the full documentation while it's compiling. 
If the TL;DR doesn't work, read the full documentation.

# TL;DR

For this TL;DR we assume that we're working from the current wokring directory:
```
/scratch/username/
```
if nothing is specified, you should assume that this is the current working directory, like in:
```
$ cd cosmo-pompa
```
which would put us in the following directory:
```
/scratch/username/cosmo-pompa
```
All the instructions obviously apply for any working directory.

As we're loading modules and changing the environment, we assume that everything is executed in the **same terminal**.

## Building Stella and the Dycore

Clone this repository:
```
$ git clone git@github.com:PallasKat/eb-cosmo.git
```
and go in it's directory:
```
$ cd eb-cosmo
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
# EXECUTE THE FOLLOWING COMMANDS IN YOUR TERMINAL #
# BEFORE INSTALLING COSMO                         #

export EASYBUILD_PREFIX=/scratch/username/install/
export EASYBUILD_BUILDPATH=/tmp/username/easybuild
module load daint-gpu
module load EasyBuild-custom
```
and execute them in your current environment (i.e. terminal).

## Building Cosmo-pompa

Change to the directory containing the Cosmo source you want to compile.
For example, let's assume that the Cosmo we want to compile is here:
```
/scratch/username/cosmo-pompa/cosmo
```
So we go there:
```
$ cd /scratch/username/cosmo-pompa/cosmo
```
and we start by executing the Cosmo builds script to fetch the environnement (it's a git submodule of cosmo-pompa):
```
$ test/jenkins/build.sh -h
```
and replace the Daint environment by the one provided by this repository:
```
$ cp /scratch/username/eb-cosmo/env/env.daint.sh test/jenkins/env/
```

As we previously installed the Cordex DyCore for CPU, we load the all corresponding modules:  
```
$ module load DYCORE_CRCLIM_CPU/cordex-CrayGNU-18.08-double
```
and we run the Cosmo build script:
```
$ test/jenkins/./build.sh -z -c cray -t gpu -x $EBVERSIONDYCORE_CRCLIM_GPU
```
et voila! After waiting between 60 and 90 minutes you have a working Cosmo executable.

# Extended version of the tutorial

This extended version assume that you've read the TL;DR once.
This extended version provide details to better understand the new process of building the libraries needed for the Cosmo model.

It's important to notice that this current approach is diverging from the one used by MeteoSwiss and thus cannot be yet applied on Kesch.
This also mean that currently we cannot (and we won't) merge it into the `crclim` branch of Cosmo-pompa.
That's why all this stays for now in its own repository.

## About the repository

Clone this repository:
```
$ git clone git@github.com:PallasKat/eb-cosmo.git
```
and go in it's directory:
```
$ cd eb-cosmo
```
where you can see that there are several easybuild (EB) config files.
Two of them are for STELLA:
```
STELLA_CORDEX-CrayGNU-18.08-double.eb
STELLA_CRCLIM-CrayGNU-18.08-double.eb
```
and the rest is for the C++ Dycore:
```
DYCORE_CORDEX_CPU-CrayGNU-18.08-double.eb
DYCORE_CORDEX_GPU-CrayGNU-18.08-double.eb
DYCORE_CRCLIM_CPU-CrayGNU-18.08-double.eb
DYCORE_CRCLIM_GPU-CrayGNU-18.08-double.eb
```
They respectively contain the information to build Stella and the Dycore with EB.
You can deduce from the filenames that some are for the crCLIM or Cordex setup, and also to target the either the CPU or GPU.

The difference compared to the classic build scripts is that EB is going to make Stella and the Dycore available as modules on Daint. 
So once it's install you'll have to load the needed Dycore depending on the configuration you need for Cosmo.

You don't have to invoke EB yourself, you should only use the provided  "driver" script `build_crclim_libs.sh`. 
This script drives the call to EB to build the Stella and Dycore libraries and make them available as modules.
The goal is to minimize the steps the domain scientist need to do and ensure coherence between the build.

You can also see that there is a directory `env`.
It contains environment specific to the post-update Daint.
However as there is currently no agreement between MeteoSwiss and the CSCS on an unified way of building the model, the `buildenv` is not going to be updated.
So these files need to be manually copied before building Cosmo.

## Building Stella and the Dycore

You can build and install Stella and the Dycore with the driver script `build_crclim_libs.sh`.
To invoke the script you should provide at least:
  * the project (i.e. crclim or cordex), 
  * the targeted architecture (i.e. cpu or gpu) 
  * and an install path. It's important to note that the install path must exist before executing the script.

The command line help describes what you should pass to the script:
```
$ ./build_crclim_libs.sh -h
Usage: build_crclim_libs.sh -p project -t target [-z]

Arguments:
-h           show this help message and exit
-p project   build project: crclim or cordex
-t target    build target: cpu or gpu
-i path      install path for the modules (EB prefix, the directory must exist)
-z           clean any existing repository, reclone it, and create new source archive
```

The script fetch (clone) the `crclim` branch of the `stella` and the `cosmo-pompa` repositories from the `C2SM-RCM` organization.
This is the default behavior and it's hardcoded in the script. 
It's important that the script is cloning Stella and the Dycore in the current working directory and it's expecting to find the Stella and Dycore directories in the current working directory.  

Once the sources are fetched, it creates an archive of the sources (a `tar.gz` file):
  * One for Stella: `stella.tar.gz`
  * one for the Dycore: `dycore.tar.gz`.

This is because we don't have release yet and EB is expecting an archive from a release or a files list.
The easiest way to hack it was to create the "release" (i.e. the archive) on the fly from the cloned repositories. 

The script also invokes EB to build `grib_api` and `libgrib_api`, through CSCS EB config files (however this is failing), as long with Stella and the C++ Dycore:
```
$ ./build_crclim_libs.sh -t gpu -p cordex -i  /scratch/username/install/
```
in this example with `-p cordex` we ensure that Stella is built with `KFLAT=8` and `KLEVEL=40` and that the Dycore will be build for GPU and use the corresponding version of Stella. 
The correct version is selected according the values provided with the flags:
  * `-p crclim -t cpu` : Stella with KSIZE=60 and KFLAT=19 and a CPU Dycore
  * `-p crclim -t gpu` : Stella with KSIZE=60 and KFLAT=19 and a GPU Dycore 
  * `-p cordex -t cpu` : Stella with KSIZE=40 and KFLAT=8  and a CPU Dycore
  * `-p cordex -t gpu` : Stella with KSIZE=40 and KFLAT=8  and a GPU Dycore 

No other version are currently available.
If you need another one, please open a "GitHub issue" on that repository.

The script starts to print the requested configuration.
For example:
```
$ ./build_crclim_libs.sh -t gpu -p crclim
===========================================================
Compiling STELLA and the C++ DyCore as modules
===========================================================
Date             : sam oct 20 23:05:46 CEST 2018
Machine          : daint666
User             : username
Architecture
   CPU           : OFF
   GPU           : ON
Project
   crCRLIM       : ON
   Cordex        : OFF
Cleanup          : OFF
Install path     : /scratch/username/install/
===========================================================
```
so you should double check that everything is fine.

At end of the compilation, the script prints what you should export and what to load:
```
# EXECUTE THE FOLLOWING COMMANDS IN YOUR TERMINAL #
# BEFORE INSTALLING COSMO                         #

export EASYBUILD_PREFIX=/scratch/username/install/
export EASYBUILD_BUILDPATH=/tmp/username/easybuild
module load daint-gpu
module load EasyBuild-custom
```
copy and past them in your terminal before trying to load the Stella and Dycore modules.
Now both libraries (Stella and the DyCore) will be available through modules loading.

## Building COSMO

Once the needed modules are loaded, you can see that the installed libraries are available:
```
------------ /scratch/username/install/modules/all ------------
DYCORE_CRCLIM_GPU/crclim-CrayGNU-18.08-double 
Serialbox/2.4.1-CrayGNU-18.08                 
libgrib1_crclim/a1e4271-CrayCCE-18.08 
STELLA_CRCLIM/crclim-CrayGNU-18.08-double     
grib_api/1.13.1-CrayCCE-18.08
```
You can see here that we have access to a Dycore with the crCLIM setup compiled for GPU (`DYCORE_CRCLIM_GPU`).
To use it, you load it as any other module:
```
module load DYCORE_CRCLIM_GPU/crclim-CrayGNU-18.08-double
```
which export a variable `EBROOTDYCORE_CRCLIM_GPU`:
```
$ echo $EBROOTDYCORE_CRCLIM_GPU
/scratch/username/install/software/DYCORE_CRCLIM_GPU/crclim-CrayGNU-18.08-double
```
and point to the installed Dycore.

The variable name will change according the setup you decided to build.
You have:
  * `EBROOTDYCORE_CRCLIM_CPU` : Dycore with crCLIM setup (KSIZE=60 and KFLAT=19) for CPU
  * `EBROOTDYCORE_CRCLIM_GPU` : Dycore with crCLIM setup (KSIZE=60 and KFLAT=19) for GPU
  * `EBROOTDYCORE_CORDEX_CPU` : Dycore with crCLIM setup (KSIZE=40 and KFLAT=9)  for CPU
  * `EBROOTDYCORE_CORDEX_GPU` : Dycore with crCLIM setup (KSIZE=40 and KFLAT=9)  for GPU


If you're unsure of the variable name, you can request details of the module with `module show`:
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
where you see the available environnement variables the module will set.
In our case we're only interested by the one pointing to the installed Dycore.

Once this is done, we can almost build Cosmo the classical way, that is to say with build script.

Change to the directory containing the Cosmo source you want to compile.
For example, we assume that the Cosmo we want to compile is here:
```
/scratch/username/cosmo-pompa/cosmo
```
So we change directory:
```
$ cd /scratch/username/cosmo-pompa/cosmo
```
and execute the Cosmo builds script to fetch the environnement (as it is a git submodule):
```
$ test/jenkins/build.sh -h
```
and replace the Daint environment by the one provided by this repository:
```
$ cp /scratch/username/eb-cosmo/env/env.daint.sh test/jenkins/env/
```


you can almost start to build Cosmo, you just need to replace the `env.daint.sh` as the one in the `buildenv` is not adapted anymore to build the model on Daint.
Start by triggering environment fetching by executing:
```
$ cd cosmo-pompa/cosmo
$ test/jenkins/build.sh -h
```
then replace the Daint environment:
```
$ cp env.daint.sh test/jenkins/env/
```
and execute the build script as usual:
```
$ test/jenkins/./build.sh -c cray -t gpu -x $EBROOTDYCORE_CRCLIM_GPU
```
and you're done! After waiting between 60 to 90 minutes, you have a working Cosmo executable.

# Troubleshooting
This section covers some issues that you may encounter when trying to build the model.
If you get some undocumented issue please open a "GitHub issue" on this repository to improve this section. 

## Modules hell

It's very likely that you end up in a modules hell.
The issue can occurs either before executing the driving script:
```
EasyBuild-custom/cscs(81):ERROR:102: Tcl command execution failed: if { [ string match *daint* $system ] || [ string match *dom* $system ] } {
    setenv EASYBUILD_OPTARCH                    $::env(CRAY_CPU_TARGET)
    setenv EASYBUILD_RECURSIVE_MODULE_UNLOAD    0
} elseif { [ string match *esch* $system ] } {
    setenv EASYBUILD_MODULE_NAMING_SCHEME       LowercaseModuleNamingScheme   
} else {
    setenv EASYBUILD_RECURSIVE_MODULE_UNLOAD    1
}
```
or while executing the Cosmo build script:
```
daint-gpu(30):ERROR:105: Unable to locate a modulefile for 'craype-haswell'
```
in both case logout from the machine and login again to have a fresh environment.

If the problem occurred while invoking the Cosmo build script, do not forget to export and load the corresponding modules.
First the environnement:
```
$ export EASYBUILD_PREFIX=/scratch/username/install/
$ export EASYBUILD_BUILDPATH=/tmp/username/easybuild
$ module load daint-gpu
$ module load EasyBuild-custom
```
and then the needed Dycore (in this example the crCLIM setup for GPU):
```
$ module load DYCORE_CRCLIM_GPU/crclim-CrayGNU-18.08-double
```
and try to execute the Cosmo build script again.

If this doesn't solve your issue, please open a "GitHub issue" on this repository.

## Fatal cloning

As the driving script is expecting to find the Stella and the Dycore directories in the current working directory, you may be unable to clone it again.
Indeed if any of the directories already exists, you'll get:
```
fatal: destination path 'cosmo-pompa' already exists and is not an empty directory.
```
and nothing is cloned.

The `-z` flag is there to solve that issue and ensure that the repositories are **deleted** before cloning them again.
The deletion occures **without warning and delay**.
So be careful otherwise you may loose your work.

## EB modules warning

During the compilation with EB, messages of that the current messages:
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
```
but these ones can be ignored.

## Impossible to use EB for Grib 

Currently the installed libraries with CSCS EB config cannot be used with the model.
Indeed the `option.lib` files in the repository for both architectures:
  * eb-cosmo/env/Options.lib.cpu
  * eb-cosmo/env/Options.lib.gpu

use the EB exported variables but this trigger the following error when running the model:
```
install/./cosmo_crclim_cpu: error while loading shared libraries: libgrib_api_f90.so.0: cannot open shared object file: No such file or directory
```
There is **no fix** for that issue for now.



