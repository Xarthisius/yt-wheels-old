#!/bin/bash

set -e -x

export YT_VER=3.4.0

# Install hg
#export TEMP_BIN=/opt/python/cp27-cp27m/bin
#${TEMP_BIN}/pip install mercurial

tar xf /io/yt-${YT_VER}.tar.gz -C /tmp
cd /tmp/yt-${YT_VER}

#if [ -d /io/yt ] ; then
#   cd /io/yt
#   ${TEMP_BIN}/hg pull
#   ${TEMP_BIN}/hg update
#else
#   ${TEMP_BIN}/hg clone https://bitbucket.org/yt_analysis/yt /io/yt -b yt
#   cd /io/yt
#fi
#
#${TEMP_BIN}/hg update -C yt-3.3.2

# Compile wheels

if [[ $(arch) == i686 ]] ; then
   yum install -qy libpng-devel.i386
   ( pushd /tmp &> /dev/null && \
     wget -q http://download.savannah.gnu.org/releases/freetype/freetype-2.4.12.tar.gz && \
     tar xf freetype-2.4.12.tar.gz && \
     cd /tmp/freetype-2.4.12 && \
     ./configure --prefix=/usr && \
     make -j4 && \
     make install && \
     popd &> /dev/null )
   export mpl="matplotlib==1.5.3"
else
   export mpl=matplotlib
fi
export PYBIN=/opt/python/${PYVER}/bin
echo "building for ${PYBIN}"
if [[ $PYVER == cp36-cp36m || $(arch) == i686 ]] ; then
   ${PYBIN}/pip install "numpy==1.11.3" "Cython>=0.24"
else
   ${PYBIN}/pip install "numpy==1.10.4" "Cython>=0.24"
fi
${PYBIN}/pip wheel --no-deps . -w wheelhouse/

for whl in wheelhouse/yt*.whl; do
   auditwheel repair $whl -w /io/wheelhouse/
   rm $whl
done

if [[ $PYVER == cp27* ]] ; then
   export CPPFLAGS="-DO_CLOEXEC=0"
fi

${PYBIN}/pip install $mpl sympy "setuptools>=19.6" "IPython"
${PYBIN}/pip install yt --no-index -f /io/wheelhouse
cd $HOME; ${PYBIN}/python -c 'import yt; print(yt.__version__)'

rm -rf /tmp/yt-${YT_VER}
