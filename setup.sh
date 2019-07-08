#!/bin/bash

# Author: Tom Bellis
version=1.0
trap "exit 1" TERM

# Error handling
error() {
  local pid=$$
  local parent_lineno="$1"
  local message="$2"
  local code="${3:-1}"
  if [[ -n "$message" ]] ; then
    echo -e "\e[31mError \e[0m on or near line ${parent_lineno}: \e[101m${message}; \e[0m exiting with status ${code}"
  else
    echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
  fi
  kill -s TERM $pid
  exit "${code}"
}

# Display splash
cat ./splash
echo -e "\n"
echo -e "\e[40m\e[97mMapper-tileup Installer \e[0m"
echo -e "\e[40m\e[97mVersion: $version \e[0m"
echo -e "\e[40m\e[97mAuthor: Tom Bellis \e[0m \n"
echo -e  "\e[1mNB: Ensure you are executing this script with a privileged account e.g \e[91mroot \e[0m\n"

chmod +x ./bin/tileup

apt_update()
{
    # Update the apt repo
    apt-get update 1>> /dev/null 2>>/dev/null || error ${LINENO} "Failed to run apt-get update"
}

pkg_install()
{
    # Install Ruby, Imagemagick
    apt-get install ruby ruby-dev make gcc build-essential checkinstall -y 1>> /dev/null || error ${LINENO} "Failed to install core packages"
    apt-get build-dep imagemagick -y 1>>/dev/null|| error ${LINENO} "Failed to build dependancies for imagemagick"
}

wget_imagemagick()
{
    cd /usr/local/src/
    wget http://www.imagemagick.org/download/releases/ImageMagick-6.9.7-10.tar.xz -q 1>> /dev/null || error ${LINENO} "Unable to download ImageMagick"
}

make_imagemagick()
{
    cd /usr/local/src/
    tar -xJf ImageMagick-6.9.7-10.tar.xz 1>> /dev/null
    cd ImageMagick-6.9.7-10
    bash ./configure --disable-static --with-modules --without-perl --without-magick-plus-plus --with-quantum-depth=8 --with-gs-font-dir=/usr/share/fonts/type1/gsfonts/ 1>> /dev/null
    make  1>> /dev/null
    make install  1>> /dev/null
}

test_imagemagick()
{
    magick -help 1>>/dev/null || error ${LINENO} "Unable to run imagemagick"
}

install_dep()
{
    # Install rmagick
    gem install rmagick 1>> /dev/null || error ${LINENO} "Failed to install rmagick gem"
    ldconfig /usr/local/lib
}

build_gem()
{
    # Building gemspec
    gem build tileup.gemspec 1>> /dev/null || error ${LINENO} "Failed to build gemspec"
}

install_gem()
{
    # Install gem
    gem install tileup-*.gem 1>> /dev/null || error ${LINENO} "Failed to install gem"
}

showLoading()
{
    mypid=$!
    loadingText=$1

    echo -ne "$loadingText\r"

    while kill -0 $mypid 2>/dev/null; do
        echo -ne "$loadingText.\r"
        sleep 0.5
        echo -ne "$loadingText..\r"
        sleep 0.5
        echo -ne "$loadingText...\r"
        sleep 0.5
        echo -ne "\r\033[K"
        echo -ne "$loadingText\r"
        sleep 0.5
    done

    echo -e "$loadingText...\e[32m COMPLETE \e[0m"
}

main()
{
    apt_update & showLoading "Updating apt-get repository"
    pkg_install & showLoading "Installing core packages"
    wget_imagemagick & showLoading "Downloading ImageMagick source"
    make_imagemagick & showLoading "Compiling ImageMagick"
    install_dep & showLoading "Installing gem dependancies"
    build_gem & showLoading "Building gem"
    install_gem & showLoading "Installing Mapper-tileup gem"

    echo -e "\e[7mMapper-tileup\e[0m is now \e[32minstalled\e[0m. This is accessible through the \e[7m tileup \e[0m command"
}

# find user account
if [ "$(whoami)" != 'root' ]; then
    echo -e "Run this script as \e[31mroot \e[0mor try \e[7m sudo bash setup.sh \e[0m"
else
    main
fi
