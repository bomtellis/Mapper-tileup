#!/bin/bash

# Author: Tom Bellis
version=0.0.1

# Display splash
echo "Greetings! Welcome to Mapper-tileup"
cat ./splash
echo "Installer Version $version"

apt_update()
{
    # Update the apt repo
    apt-get update || echo "Failed to install apt-get repository" && exit 0
}

pkg_install()
{
    # Install Ruby, Imagemagick
    apt-get install ruby imagemagick -y || echo "Failed to install core packages" && exit 0
}

install_dep()
{
    # Install rmagick
    gem install rmagick  || echo "Failed to install rmagick gem" && exit 0
}

build_gem()
{
    # Building gemspec
    gem build tileup.gemspec || echo "Failed to build gemspec" && exit 0
}

install_gem()
{
    # Install gem
    gem install tileup-*.gem || echo "Failed to install tileup gem" && exit 0
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

    echo "$loadingText...COMPLETE"
}

main()
{
    apt_update && showLoading "Updating apt-get repository"
    pkg_install && showLoading "Installing core packages"
    install_dep && showLoading "Installing gem dependancies"
    build_gem && showLoading "Building gem"
    install_gem && showLoading "Installing Mapper-tileup"

    echo "Mapper-tileup is now installed. Ths is accessible through the 'tileup' command"
}

trap main 0

# Error handling
error() {
  local parent_lineno="$1"
  local message="$2"
  local code="${3:-1}"
  if [[ -n "$message" ]] ; then
    echo "Error on or near line ${parent_lineno}: ${message}; exiting with status ${code}"
  else
    echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
  fi
  exit "${code}"
}

trap 'error ${LINENO}' ERR
