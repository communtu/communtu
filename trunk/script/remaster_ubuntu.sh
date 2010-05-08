#! /bin/bash

#
##
## Script to remaster an ubuntu live CD
##
#
#
# Overview:
# =========
#
# This script allows to customize an Ubuntu live CD in 3 simple steps:
#
#  1. extract the contents of an ubuntu CD ISO image to your hard drive
#
#  2. chroot to the working area containing the extracted CD
#     contents. This allows to do all the /etc configs, aptitude
#     purge/install, etc. to prepare the future ISO image
#
#  3. generate a new ISO image containing the (hopefully modified)
#     working area you just prepared
#
#
# Tested configurations:
# ======================
#
# - Tested with the jaunty/x86_32 (9.04) live CD image on an
#   intrepid/x86_64 (8.10) host
#
#
# Prerequisites:
# ==============
#
#  - around 3GB available on the hard drive
#  - aptitude install squashfs-tools genisoimage
#  - to install on a bootable USB stick: aptitude install unetbootin
#
#
# Usage:
# ======
#
#  All the following commands MUST be run as root (sudo).
#
#  - this_script.sh extract /path/to/original/ubuntu.iso /path/to/working/area
#    => This will extract the contents of the ISO into 2 subdirectories of
#       /path/to/working/area/ (should be empty initially):
#         extract-cd/: the files needed to boot (isolinux config,
#                      kernel, initramfs, etc.), but not the root FS
#         edit/:       the root file system (complete with /etc, /usr, etc.)
#
#  - this_script.sh chroot /path/to/working/area
#    => This will start a root bash shell inside the root file
#       system. Takes care of mounting /dev, /proc, /sys. In that
#       shell, you can aptitude purge/install, edit /etc files, create
#       users, even start X applications (xauth is configured),
#       etc. But do NOT edit anything in /dev, as this will affect
#       your host (the host's /dev is mounted inside the chroot:
#       anything changed in the chroot's /dev is also changed in the
#       host's /dev !): avoid doing rm in /dev at this point :) !
#       Beware also that issuing some aptitude install commands might
#       start /etc/init.d daemons which will run inside the chroot,
#       even after you exited from it: you might have to kill these
#       manually so that they don't interfere with the host
#       Note: This operation will also copy the host's apt config into
#       the working area, so that the same repositories can be
#       used. The original ubuntu apt config will be restored when the
#       regen command is issued
#
#  - this_script.sh regen /path/to/working/area SOME_NAME /path/to/dest/my.iso
#    => Generate a new ISO file from the extract-cd/ and edit/ dirs of
#       the working area. The SOME_NAME param is just a dummy tag for
#       the ISO image. The original apt configuration will be restored
#       before the image is generated. You will still be able to use
#       the chroot operation after a regen
#
#  - this_script.sh release /path/to/working/area
#    => You will probably never need to use this operation
#       manually. It is essentially an internal command used by the
#       regen operation. But it might be important to use manually if
#       you plan to remove /path/to/working/area (eg. rm -rf) after
#       you chroot'ed to it at least once. This command makes sure the
#       host will not be impacted by the removal of the working area
#       (eg. it will unmount the /dev mount in the chroot). After this
#       command, it is safe to remove completely the working area. You
#       will still be able to use the chroot operation after a release
#
# The 'extract' and 'regen' operations will be verbose and stop at the
# first error that occurs. You can of course run the 'extract'
# operation just once, and run the 'chroot' or 'regen' operations
# thousands of times on the same working area. You can also run
# several 'chroot' sessions in parallel. But be sure NOT to run a
# 'chroot' operation while a 'regen' is in progress.
#
#
# Advanced customization:
# =======================
#
# If you're planning to update the kernel, or to change the live user
# configuration, follow the instructions in [1] (see references
# below).
#
#
# To test:
# ========
#
# Try VirtualBox OSE on the resulting iso file. Or burn a ISO and
# reboot on the CD you just created. Or use unetbootin to create a
# bootable USB memory stick.
#
#
# References:
# ===========
#
#  [1] https://help.ubuntu.com/community/LiveCDCustomization
#  [2] http://brainstorms.in/?p=356
#
#
# Credits:
# ========
#   d2 (david /at/ decotigny point fr): http://david.decotigny.fr
#   http://david.decotigny.fr/wiki/wakka.php?wiki=RemasterUbuntu
#

SVN_REVISION='$Id: remaster-ubuntu.sh 682 2009-05-23 16:37:39Z ddecotig $'

_usage () {
    [ -n "$1" ] && echo -e "\n\033[31;1m$1\033[m\n" >&2
    cat >&2 <<EOF
Usage: $0 command options...

Commands & options:
   extract /path/to/ubuntu.iso /path/to/working_area : create the working area
   chroot  /path/to/working_area                     : start a shell in the WA
   release /path/to/working_area                     : umount special WA mounts
   regen   /path/to/working_area IMGNAME /path/to/new.iso: create new iso image
EOF
    exit 1
}


# Check that we're the root user
[ x`id -u`-`id -g`y = x0-0y ] || _usage "This script requires root privileges"


_finalize_extract () {
    umount "$d/squashfs" >/dev/null 2>&1 && rmdir "$d/squashfs"
    umount "$d/mnt"      >/dev/null 2>&1 && rmdir "$d/mnt"

    trap "" KILL EXIT QUIT TERM INT
}


extract_img () {
    [ $# != 2 ] && _usage "Invalid number of arguments for extract command"

    imgfile="$1"
    d="$2"

    [ -f "$imgfile" ] || _usage "Invalid ISO file $imgfile"
    [ -d "$d/edit" ] && _usage "Destination working area $d already exists"

    [ ! -d "$d" ] && mkdir "$d"

    echo "# Preparing working area $d for $imgfile"

    trap "_finalize_extract" KILL EXIT QUIT TERM INT
    set -x

    mkdir "$d/mnt"
    mount -o loop "$imgfile" "$d/mnt"

    mkdir "$d/extract-cd"
    rsync --exclude=/casper/filesystem.squashfs -a \
	"$d/mnt/" "$d/extract-cd"

    mkdir "$d/squashfs"
    mount -t squashfs -o loop "$d/mnt/casper/filesystem.squashfs" \
                                    "$d/squashfs"
    mkdir "$d/edit"
    rsync -a "$d/squashfs/" "$d/edit"

    mkdir "$d/orig"
    cp -a "$d/edit/etc/hosts" \
	"$d/orig/etc-hosts" >/dev/null 2>&1 || true
    cp -a "$d/edit/etc/resolv.conf" \
	"$d/orig/etc-resolv.conf"  >/dev/null 2>&1 || true
    cp -a "$d/edit/etc/mtab" \
	"$d/orig/etc-mtab"  >/dev/null 2>&1 || true
    tar cf "$d/orig/etc-apt-conf.tar" -C "$d/edit/etc" apt
}


chroot_live () {
    [ $# != 1 ] && _usage "Invalid number of arguments for chroot command"

    d="$1"
    [ -d "$d/edit" ] || _usage "Invalid working area $d"

    cp /etc/resolv.conf /etc/hosts "$d/edit/etc/"
    cp -fa /etc/apt "$d/edit/etc/"

    mkdir -p "$d/edit/tmp/remaster-xchg"

    echo -e "\033[1m"
    cat >&2 <<EOF
IMPORTANT: do not ever try to remove the $d (eg. rm -r) area
           unless you ran either the 'release' or 'regen' command beforehand !
EOF
    echo -e "\033[m"

    [ -d "$d/edit/dev/usb" ] || mount --rbind /dev/ "$d/edit/dev"

    env_key=`uuidgen`

    main_sh="/tmp/remaster-xchg/main-$env_key.sh"
    cp "$0" "$d/edit/$main_sh"
    cat > "$d/edit/tmp/remaster-xchg/startenv-$env_key.sh" <<EOF
echo `xauth nlist $DISPLAY` | xauth nmerge -
EOF

    exec chroot "$d"/edit env ENV_KEY="$env_key" DISPLAY="$DISPLAY" \
	/bin/sh "$main_sh" _actual_chroot_
}


_actual_chroot_ () {
    [ -f /proc/cpuinfo ] || mount -t proc none /proc
    [ -d /sys/class ]    || mount -t sysfs none /sys

    HOME=/root
    LC_ALL=C
    export HOME LC_ALL
    unset XAUTHORITY

    . /tmp/remaster-xchg/startenv-$ENV_KEY.sh
    rm -f /tmp/remaster-xchg/startenv-$ENV_KEY.sh
    rm -f "$0"

    cd /root
    exec env debian_chroot="remaster" /bin/bash -l
}


release_live () {
    [ $# != 1 ] && _usage "Invalid number of arguments for release command"

    d="$1"
    [ -d "$d/edit" ] || _usage "Invalid working area $d"

    while [ -d "$d/edit/dev/usb" ] ; do umount -fl "$d/edit/dev" ; done
    while [ -d "$d/edit/sys/class" ] ; do umount -fl "$d/edit/sys" ; done
    while [ -f "$d/edit/proc/cpuinfo" ] ; do umount -fl "$d/edit/proc" ; done
}


regenerate_img () {
    [ $# != 3 ] && _usage "Invalid number of arguments for regen command"

    d="$1"
    IMAGE_NAME="$2"

    # Determine absolute path to output ISO file (we'll do a chdir later)
    od=`dirname "$3"`
    od=`cd "$od" && /bin/pwd`
    outfile="$od"/`basename "$3"`

    [ -d "$d/edit" ] || _usage "Invalid working area $d"
    [ -f "$outfile" ] && _usage "Destination iso file $outfile already exists"

    echo "# Creating image $IMAGE_NAME as $outfile from $d"
    set -x

    release_live "$d"

    chroot "$d/edit" aptitude clean

    rm -f "$d/edit/etc/hosts" "$d/edit/etc/resolv.conf" "$d/edit/etc/mtab" \
	"$d/edit/root/.bash_history" "$d/edit/root/.Xauthority"
#    rm -rf "$d/edit/etc/apt"
    rm -rf "$d/edit/tmp/*"

    cp -a "$d/orig/etc-hosts" \
	"$d/edit/etc/hosts" >/dev/null 2>&1 || true
    cp -a "$d/orig/etc-resolv.conf" \
	"$d/edit/etc/resolv.conf" >/dev/null 2>&1 || true
    cp -a "$d/orig/etc-mtab" \
	"$d/edit/etc/mtab" >/dev/null 2>&1 || true
#    tar xf "$d/orig/etc-apt-conf.tar" -C "$d/edit/etc/"

    chmod +w "$d/extract-cd"/casper/filesystem.manifest
    chroot "$d/edit" dpkg-query -W --showformat='${Package} ${Version}\n'\
	> "$d/filesystem.manifest"
    cp -f "$d/filesystem.manifest" \
	"$d/extract-cd"/casper/filesystem.manifest
    cp -f "$d/filesystem.manifest" \
	"$d/extract-cd/casper/filesystem.manifest-desktop"

    rm -f "$d/extract-cd/casper/filesystem.squashfs"
    mksquashfs "$d/edit" \
	"$d/extract-cd/casper/filesystem.squashfs" # -nolzma

    # TODO: Edit extract-cd/README.diskdefines

    for f in ubiquity casper live-initramfs user-setup discover \
	xresprobe os-prober libdebian-installer ; do
	sed -i "/${f}/d" "$d/extract-cd/casper/filesystem.manifest-desktop"
    done

    rm "$d/extract-cd/md5sum.txt"
    sh -c "cd '$d/extract-cd' && find . -type f -print0 | xargs -0 md5sum > md5sum.txt"

    pushd "$d/extract-cd" >/dev/null
    mkisofs -r -V "$IMAGE_NAME" -cache-inodes -J -l \
	-b isolinux/isolinux.bin -c isolinux/boot.cat \
	-no-emul-boot -boot-load-size 4 -boot-info-table \
	-o "$outfile" .
    popd >/dev/null

}


case x"$1" in
    xextract) shift ; set -e ; extract_img "$@";;
    xchroot) shift ; set -e ; chroot_live "$@" ;;
    xrelease) shift ; set -e ; release_live "$@" ;;
    xregen) shift ; set -e ; regenerate_img "$@";;
    x_actual_chroot_) _actual_chroot_ ;;
    *) _usage "Invalid command $1" ;;
esac
