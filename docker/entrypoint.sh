#!/bin/sh
export SRILM=/opt/tools/srilm
export PATH=${PATH}:${SRILM}/bin:${SRILM}/bin/i686-m64

export WENET_DIR=/opt/wenet
export WENET_BUILD_DIR=${WENET_DIR}/runtime/server/x86/build
export OPENFST_PREFIX_DIR=${WENET_DIR}/runtime/server/x86/fc_base/openfst-subbuild/openfst-populate-prefix
export PATH=${WENET_BUILD_DIR}:${WENET_BUILD_DIR}/kaldi:${OPENFST_PREFIX_DIR}/bin:$PATH
export PATH=${WENET_DIR}/tools:${WENET_DIR}/tools/fst:$PATH


export PYTHONPATH=${WENET_DIR}:$PYTHONPATH
# NOTE(kan-bayashi): Use UTF-8 in Python to avoid UnicodeDecodeError when LC_ALL=C
export PYTHONIOENCODING=UTF-8

exec "$@"
