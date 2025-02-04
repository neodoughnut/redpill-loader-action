
#!/bin/bash

# prepare build tools
sudo apt-get update && sudo apt-get install --yes --no-install-recommends ca-certificates build-essential git libssl-dev curl cpio bspatch vim gettext bc bison flex dosfstools kmod jq

root=`pwd`
mkdir DS3622xsp-7.0.1
mkdir output
cd DS3622xsp-7.0.1

# download redpill
git clone -b develop --depth=1 https://github.com/dogodefi/redpill-lkm.git
git clone -b develop --depth=1 https://github.com/dogodefi/redpill-load.git

# download syno toolkit
curl --location "https://global.download.synology.com/download/ToolChain/toolkit/7.0/broadwellnk/ds.broadwellnk-7.0.dev.txz" --output ds.broadwellnk-7.0.dev.txz

mkdir broadwellnk
tar -C./broadwellnk/ -xf ds.broadwellnk-7.0.dev.txz usr/local/x86_64-pc-linux-gnu/x86_64-pc-linux-gnu/sys-root/usr/lib/modules/DSM-7.0/build

# build redpill-lkm
cd redpill-lkm
sed -i 's/   -std=gnu89/   -std=gnu89 -fno-pie/' ../broadwellnk/usr/local/x86_64-pc-linux-gnu/x86_64-pc-linux-gnu/sys-root/usr/lib/modules/DSM-7.0/build/Makefile
make LINUX_SRC=../broadwellnk/usr/local/x86_64-pc-linux-gnu/x86_64-pc-linux-gnu/sys-root/usr/lib/modules/DSM-7.0/build dev-v7
read -a KVERS <<< "$(sudo modinfo --field=vermagic redpill.ko)" && cp -fv redpill.ko ../redpill-load/ext/rp-lkm/redpill-linux-v${KVERS[0]}.ko || exit 1
cd ..

# build redpill-load
cd redpill-load
cp -f ${root}/user_config.junDS3622xs+.json ./user_config.json
./ext-manager.sh add https://raw.githubusercontent.com/jumkey/redpill-load/develop/redpill-virtio/rpext-index.json
./ext-manager.sh add https://raw.githubusercontent.com/pocopico/rp-ext/main/mpt3sas/rpext-index.json
./ext-manager.sh add https://raw.githubusercontent.com/pocopico/redpill-load/master/redpill-acpid/rpext-index.json
./ext-manager.sh add https://raw.githubusercontent.com/pocopico/redpill-load/develop/redpill-misc/rpext-index.json
./ext-manager.sh add https://raw.githubusercontent.com/neodoughnut/redpill-hyperv/main/hyper-v/rpext-index.json
sudo BRP_JUN_MOD=1 BRP_DEBUG=1 ./build-loader.sh 'DS3622xs+' '7.0.1-42218'
#sudo ./build-loader-old.sh 'DS3622xs+' '7.0.1-42218'
mv images/redpill-DS3622xs+_7.0.1-4221*.img ${root}/output/
cd ${root}
