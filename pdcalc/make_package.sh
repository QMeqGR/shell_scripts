#!/bin/sh

package=pdcalc

# this script packages up the $package scripts
# and archives the tarball

ARCHIVE=$HOME/src/archive
TEMP_DIR="temp_dir_"$package"_archive"

    version=`cat $package.ver | grep package_version | grep = | awk -F= '(NR==1){print $2}'`
package_top=`cat $package.ver | grep PACKAGE_TOP     | grep = | awk -F= '(NR==1){print $2}'`

working_dir=`pwd`


if [ "$working_dir" != "$package_top" ]; then
    echo "working_dir= "$working_dir
    echo "package_top= "$package_top
    echo "You must be in $package_top to run this script."
    echo "exiting"
    exit
fi

tarball=$package"_scripts"-$version.tgz


# make a new VERSION file
echo "version "$version" "-" "`date` > tmp_version_prepend_txt
cat tmp_version_prepend_txt VERSION > tmp_new_version_file
mv -f tmp_new_version_file VERSION
rm -f tmp_version_prepend_txt tmp_new_version_file

echo "creating tarball "$tarball
echo "package_top = "$package_top

cd $HOME
mkdir $TEMP_DIR
cd $TEMP_DIR
mkdir $package-$version
cd $package-$version
rm -f $package_top/*~
cp -ra --dereference $package_top/* .
cd ..
tar cvhzf $tarball $package-$version
cd $HOME

echo "copying tgz file to archive directory"
mv $TEMP_DIR/$tarball $ARCHIVE
rm -rf $TEMP_DIR

exit
