#!/bin/bash

set -e -x

# Probably don't want to change the stuff below this line
MANYLINUX_URL=https://nipy.bic.berkeley.edu/manylinux

# Install hg
export TEMP_BIN=/opt/python/cp27-cp27m/bin
${TEMP_BIN}/pip install mercurial

if [ -d /io/yt ] ; then
   cd /io/yt
   ${TEMP_BIN}/hg pull
   ${TEMP_BIN}/hg update
else
   ${TEMP_BIN}/hg clone https://bitbucket.org/yt_analysis/yt /io/yt -b yt
   cd /io/yt
fi

${TEMP_BIN}/hg update -C yt-3.3.0

# Compile wheels
for PYBIN in /opt/python/*/bin; do
    if [[ ${PYBIN} != *"26"* ]] && [[ ${PYBIN} != *"33"* ]]; then
        echo "building for ${PYBIN}"
        ${PYBIN}/pip install -f $MANYLINUX_URL "numpy==1.9.3" "Cython>=0.24"
        ${PYBIN}/pip wheel --no-deps . -w wheelhouse/
    else
        echo "skipping ${PYBIN}"
    fi
done


for whl in wheelhouse/yt*.whl; do
    if [[ ${whl} == *"yt"* ]]; then
        auditwheel repair $whl -w /io/wheelhouse/
    fi
done
