#!/bin/bash

set -e -x

# Probably don't want to change the stuff below this line
MANYLINUX_URL=https://nipy.bic.berkeley.edu/manylinux

cat << EOF > /etc/yum.repos.d/mercurial.selenic.com.repo
[mercurial.selenic.com]
name=mercurial.selenic.com
baseurl=https://www.mercurial-scm.org/release/centos5
enabled=1
# Temporary until we get a serious signing scheme in place,
# check https://www.mercurial-scm.org/wiki/Download again
gpgcheck=0
EOF

yum install -q -y mercurial

if [ -d /io/yt ] ; then
   cd /io/yt
   hg pull
   hg update
else
   hg clone https://bitbucket.org/yt_analysis/yt /io/yt -b yt
   cd /io/yt
fi

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
