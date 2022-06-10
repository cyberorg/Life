#!/bin/bash
#run buildlife.sh /home/life/life-chroot /home/life-extract

#cleanup
rm $1/var/lib/apt/lists/* $1/var/cache/apt/*.bin $1/root/.bash_history $1/var/log/dpkg.log $1/var/log/apt/*

#manifest
chroot $1 dpkg-query -W --showformat='${Package} ${Version}\n' > $2/casper/filesystem.manifest && cp $2/casper/filesystem.manifest $2/casper/filesystem.manifest-desktop && sed -i '/ubiquity/d' $2/casper/filesystem.manifest-desktop ; sed -i '/casper/d' $2/casper/filesystem.manifest-desktop

#make squashfile
rm $2/casper/filesystem.squashfs
nice ionice -c3 mksquashfs $1 $2/casper/filesystem.squashfs -comp xz -b 1M -Xdict-size 1M -always-use-fragments -no-recovery

#size
printf $(du -sx --block-size=1 $1 | cut -f1) > $2/casper/filesystem.size

#md5sums
cd $2
find . -type f -print0 | xargs -0 md5sum | grep -v "\./md5sum.txt" | grep -v "boot.cat" | grep -v "eltorito.img"  > md5sum.txt
cd -

#Create iso
xorriso -as mkisofs -r \
  -V 'LIFE2204' \
  -o "/home/life/Li-f-e-22.04.amd64.iso" \
  --grub2-mbr "/usr/lib/grub/i386-pc/boot_hybrid.img" \
  -partition_offset 16 \
  --mbr-force-bootable \
  -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b /home/life/efi.img \
  -appended_part_as_gpt \
  -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
  -c '/boot.catalog' \
  -b '/boot/grub/i386-pc/eltorito.img' \
    -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
  -eltorito-alt-boot \
  -e '--interval:appended_partition_2:::' \
    -no-emul-boot \
  "$2"
