#!/bin/bash

# usage:
#
#   $ ./this.sh
# or
#   $ F2PY=/usr/bin/f2py3 ./this.sh

set -euo pipefail

err(){
    echo "error $@"
    exit 1
}

[ $# -eq 1 ] || err "Please provide exactly one argument (the path to the QE directory)" && root_dir=$1

echo $root_dir

# base dir of QE distribution
#root_dir=$(readlink -f ../)

pw_src_path=$root_dir/PW/src

# Object files from the PW/src folder
pwobjs="$(find $pw_src_path -name "*.o" | grep -E -v 'generate_vdW_kernel_table|generate_rVV10_kernel_table')"

# Object files from the UtilXlib folder
utilobjs="$(find $root_dir/UtilXlib/ -name "*.o")"

# Object files from the Modules folder
modobjs="$(find $root_dir/Modules/ -name "*.o")"

[ -n "$pwobjs" ] || err "pwobjs empty"
[ -n "$utilobjs" ] || err "utilobjs empty"
[ -n "$modobjs" ] || err "modobjs empty"

# Libraries from the external FoX project
foxlibs="-L$root_dir/FoX/lib -lFoX_dom -lFoX_utils -lFoX_wcml -lFoX_wkml -lFoX_wxml -lFoX_common -lFoX_sax -lFoX_common -lFoX_fsys"

project_lib_folders=" -L$root_dir/Modules -L$root_dir/KS_Solvers -L$root_dir/FFTXlib -L$root_dir/LAXlib -L$root_dir/UtilXlib -L$root_dir/dft-d3"
project_libs="-lqemod -lks_solvers -lqefft -lqela -lutil -ldftd3qe"
project_inc_folders="-I$root_dir/Modules -I$root_dir/FFTXlib -I$root_dir/LAXlib -I$root_dir/KS_Solvers -I$root_dir/UtilXlib"

# default: systen blas,lapack and fftw, adapt as needed
linalg="-lblas -llapack"
fftw="-lfftw3"


here=$(pwd)
mod_name=total_energy
src=${mod_name}.f90
cp -v $src $pw_src_path/
cd $pw_src_path
rm -vf ${mod_name}.*.so

${F2PY:=f2py} \
    --f90exec=mpif90 \
    --f77exec=mpif90 \
    -c $src \
    -m $mod_name \
    $project_inc_folders \
    $project_lib_folders \
    $project_libs \
    $pwobjs \
    $utilobjs \
    $modobjs \
    $linalg \
    $fftw \
    $foxlibs \
    $root_dir/clib/clib.a

rm $src
mv -v ${mod_name}.*.so $here/
cd $here
