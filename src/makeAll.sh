make profile-build ARCH=x86-64-vnni COMP=gcc -j$(nproc)
strip brainlearn
mv 'brainlearn' 'Brainlearn31-x86-64-vnni'
cp ../nnue/nn-*.nnue .
make clean

make profile-build ARCH=x86-64-avx512 COMP=gcc -j$(nproc)
strip brainlearn
mv 'brainlearn' 'Brainlearn31-x86-64-avx512'
cp ../nnue/nn-*.nnue .
make clean

make profile-build ARCH=x86-64-bmi2 COMP=gcc -j$(nproc)
strip brainlearn
mv 'brainlearn' 'Brainlearn31-x86-64-bmi2'
cp ../nnue/nn-*.nnue .
make clean

make profile-build ARCH=x86-64-avx2 COMP=gcc -j$(nproc)
strip brainlearn
mv 'brainlearn' 'Brainlearn31-x86-64-avx2'
cp ../nnue/nn-*.nnue .
make clean

make profile-build ARCH=x86-64-modern COMP=gcc -j$(nproc)
strip brainlearn
mv 'brainlearn' 'Brainlearn31-x86-64-modern'
cp ../nnue/nn-*.nnue .
make clean

make profile-build ARCH=x86-64-sse41-popcnt COMP=gcc -j$(nproc)
strip brainlearn
mv 'brainlearn' 'Brainlearn31-x86-64-sse41-popcnt'
cp ../nnue/nn-*.nnue .
make clean

make profile-build ARCH=x86-64-ssse3 COMP=gcc -j$(nproc)
strip brainlearn
mv 'brainlearn' 'Brainlearn31-x86-64-ssse3'
cp ../nnue/nn-*.nnue .
make clean

make profile-build ARCH=x86-64-sse3-popcnt COMP=gcc -j$(nproc)
strip brainlearn
mv 'brainlearn' 'Brainlearn31-x86-64-sse3-popcnt'
cp ../nnue/nn-*.nnue .
make clean

make profile-build ARCH=x86-64 COMP=gcc -j$(nproc)
strip brainlearn
mv 'brainlearn' 'Brainlearn31-x86-64'
cp ../nnue/nn-*.nnue .
make clean

make profile-build ARCH=general-64 COMP=gcc -j$(nproc)
strip brainlearn
mv 'brainlearn' 'Brainlearn31-general-64'
cp ../nnue/nn-*.nnue .
make clean

make profile-build ARCH=x86-32 COMPCC=gcc
strip brainlearn
mv 'brainlearn' 'Brainlearn31-x86-32'
cp ../nnue/nn-*.nnue .
make clean

make profile-build ARCH=x86-32-old COMPCC=gcc
strip brainlearn
mv 'brainlearn' 'Brainlearn31-x86-32-old'
cp ../nnue/nn-*.nnue .
make clean

make profile-build ARCH=general-32 COMPCC=gcc
strip brainlearn
mv 'brainlearn' 'Brainlearn31-general-32'
cp ../nnue/nn-*.nnue .
make clean
