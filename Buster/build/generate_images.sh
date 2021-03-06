##requires gzip, rsync, wget, cpio, grub2, xorriso

distro="buster"

mkdir debian-files output
mkdir -p payload/source

cd debian-files
if [ -d "tmp" ]; then
   rm -r "tmp/"
fi

wget -N "http://ftp.nl.debian.org/debian/dists/$distro/main/installer-amd64/current/images/netboot/mini.iso"
cd ..

xorriso -osirrox on -indev debian-files/mini.iso -extract / iso/
cp iso/initrd.gz .
if [ $? -ne 0 ]; then
        echo "failed to retrieve initrd.gz, quitting"
        exit
fi

cp preseed.cfg payload/

#kernel_ver="$(zcat initrd.gz | cpio -t | grep -m 1 lib/modules/ | gawk -F/ '{print $3}')"

gunzip initrd.gz
if [ $? -ne 0 ]; then
        echo "failed to unpack initrd.gz, quitting"
        exit
fi
cd payload
find . | cpio -v -H newc -o -A -F ../initrd
if [ $? -ne 0 ]; then
        echo "failed to patch initrd.gz, quitting"
        exit
fi
cd ..
gzip initrd
if [ $? -ne 0 ]; then
        echo "failed to pack initrd, quitting"
        exit
fi

cp initrd.gz iso/
cp grub.cfg iso/boot/grub/

##
rm output/*
grub-mkrescue -o "output/iMac-$distro-installer.iso" iso/

rm -r iso/
rm initrd.gz
