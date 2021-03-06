#!/usr/bin/env bash
# Copyright 2017 Yash D. Saraf
# This file is part of BB-Bot.

# BB-Bot is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# BB-Bot is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with BB-Bot.  If not, see <http://www.gnu.org/licenses/>.

#FLASHABLE ZIP CREATOR
SCRIPTDIR=$(realpath `dirname $0`)
SIGNAPKDIR=$SCRIPTDIR/signapk
cd "$SCRIPTDIR/../bbx"
# ZIPALIGN=~/opt/android-sdk-linux/build-tools/25.0.2/zipalign
PEM=$SIGNAPKDIR/certificate.pem
# Uncomment this line to activate test certificate for signing
# PEM=$SIGNAPKDIR/testkey.x509.pem
PK8=$SIGNAPKDIR/testkey.pk8
SIGNAPKJAR=$SIGNAPKDIR/signapk.jar #Provided by @mfonville and @TheCrazyLex

mkzip() {
    ZIPNAME="Busybox-$1.zip"
    7za a -tzip -mx=0 $ZIPNAME * >/dev/null
    # $ZIPALIGN -f -v 4 $ZIPNAME $ZIPNAME.aligned
    # mv -fv $ZIPNAME.aligned $ZIPNAME
    java -Djava.library.path=$SIGNAPKDIR -jar $SIGNAPKJAR -w $PEM $PK8 $ZIPNAME $ZIPNAME.signed
    mv $ZIPNAME.signed ../out/$ZIPNAME
    rm $ZIPNAME
}

mkdir -p workspace
cd workspace
# for i in arm:arm64 x86:x86_64 mips:mips64
# do
i=$TO_BUILD
[[ $i == "mipseb" ]] && exit

# echo -e "\\n$i\\n"
echo "Zipping files --"
cp ../addusergroup.sh ../88-busybox.sh .
if [[ $i == "boxemup" ]]
    then
    cp -r ../AIO/META-INF .
    sed -i -e "s|^STATUS=.*|STATUS=\"$STATUS\"|;s|^DATE=.*|DATE=\"$DATE\"|;s|^VER=.*|VER=\"$VER\"|"\
     META-INF/com/google/android/update-binary
    for i in arm x86 mips
    do cp -r ../Bins/$i .
    done
    mkzip $VER-UNIVERSAL
    rm -rf *
    cp -r ../cleaner/META-INF .
    mkzip CLEANER
else
    ARCH=${i% *}
    ARCH64=${i#* }
    cp -r ../META-INF ../Bins/$ARCH/* .
    sed -i -e "s|^ARCH=.*|ARCH=$ARCH|;s|^ARCH64=.*|ARCH64=$ARCH64|;s|^STATUS=.*|STATUS=\"$STATUS\"|;\
    s|^DATE=.*|DATE=\"$DATE\"|;s|^VER=.*|VER=\"$VER\"|" META-INF/com/google/android/update-binary $SCRIPTDIR/SEE.template
    mkzip $VER-$(tr 'a-z' 'A-Z' <<< $ARCH)
    echo "Creating self extracting script --"
    rm -r bins.md5 META-INF xzdec
    unxz *xz
    7za a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on $TEMP_DIR/bbx.7z * >/dev/null
    . $SCRIPTDIR/mkSEE.sh
fi
# done
# rm -rf *
