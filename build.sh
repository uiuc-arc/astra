#usr/bin/env bash

# install CmdStan
mkdir ./cmdstan-2.16.0; tar -xf cmdstan-2.16.0.tar.gz -C ./cmdstan-2.16.0 --strip-components=1
cd ./cmdstan-2.16.0
echo "Compiling CmdStan, this could take a while..."
make build
cd ..
# install python packages
pip install -r requirements.txt
