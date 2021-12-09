#!/usr/bin/env bash

current_path=`pwd`

mkdir -p srilm
cd srilm
tar -xvzf ../srilm-1.7.3.tar.gz

# set the SRILM variable in the top-level Makefile to this directory.
cp Makefile tmpf

cat tmpf | gawk -v pwd=`pwd` '/SRILM =/{printf("SRILM = %s\n", pwd); next;} {print;}' \
  > Makefile || exit 1
rm tmpf

mtype=`sbin/machine-type`

echo HAVE_LIBLBFGS=1 >> common/Makefile.machine.$mtype
grep ADDITIONAL_INCLUDES common/Makefile.machine.$mtype | \
    sed 's|$| -I$(SRILM)/../liblbfgs-1.10/include|' \
    >> common/Makefile.machine.$mtype

grep ADDITIONAL_LDFLAGS common/Makefile.machine.$mtype | \
    sed 's|$| -L$(SRILM)/../liblbfgs-1.10/lib/ -Wl,-rpath -Wl,$(SRILM)/../liblbfgs-1.10/lib/|' \
    >> common/Makefile.machine.$mtype

make || exit

cd ..
(
  [ ! -z "${SRILM}" ] && \
    echo >&2 "SRILM variable is aleady defined. Undefining..." && \
    unset SRILM

  [ -f ./env.sh ] && . ./env.sh

  [ ! -z "${SRILM}" ] && \
    echo >&2 "SRILM config is already in env.sh" && exit

  wd=`pwd`
  wd=`readlink -f $wd || pwd`

  echo "export SRILM=$wd/srilm"
  dirs="\${PATH}"
  for directory in $(cd srilm && find bin -type d ) ; do
    dirs="$dirs:\${SRILM}/$directory"
  done
  echo "export PATH=$dirs"
) >> env.sh
