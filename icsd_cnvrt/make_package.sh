#!/bin/sh

# this script packages up the icsd_cnvrt scripts
# and archives the tarball

ARCHIVE=$HOME/src/archive
TEMP_DIR=temp_dir_icsd_scripts_archive

version=`cat icsd_cnvrt.sh | grep script_version | grep = | awk -F= '(NR==1){print $2}'`
cvt_top=`cat icsd_cnvrt.sh | grep CVT_TOP | grep = | awk -F= '(NR==1){print $2}'`

working_dir=`pwd`


if [ "$working_dir" != "$cvt_top" ]; then
    echo "working_dir= "$working_dir
    echo "cvt_top= "$cvt_top
    echo "You must be in cvt_top to run this script."
    echo "exiting"
    exit
fi

tarball=icsd_scripts-$version.tgz


# make a new VERSION file
echo "version "$version" "-" "`date` > tmp_version_prepend_txt
cat tmp_version_prepend_txt VERSION > tmp_new_version_file
mv -f tmp_new_version_file VERSION
rm -f tmp_version_prepend_txt tmp_new_version_file

echo "creating tarball "$tarball
echo "cvt_top = "$cvt_top

cd $HOME
mkdir $TEMP_DIR
cd $TEMP_DIR
mkdir icsd_cnvrt-$version
cd icsd_cnvrt-$version
rm -f $cvt_top/*~
cp -ra --dereference $cvt_top/* .
cd ..
tar cvhzf $tarball icsd_cnvrt-$version
cd $HOME

echo "copying tgz file to archive directory"
mv $TEMP_DIR/$tarball $ARCHIVE
rm -rf $TEMP_DIR

exit
