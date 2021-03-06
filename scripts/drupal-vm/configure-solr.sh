#!/bin/bash
#
# Example shell script to run post-provisioning.
#
# This script configures the default Apache Solr search core to use one of the
# Drupal Solr module's configurations. This shell script presumes you have
# `solr` in the `installed_extras`, and is currently set up for the D8 versions
# of Search API Solr.
#
# It's also intended for Solr 4.5. For other versions of Solr, refer to the
# example scripts provided by DrupalVM.

SOLR_SETUP_COMPLETE_FILE=/etc/drupal_vm_solr_config_complete

# Search API Solr module.
SOLR_DOWNLOAD="https://ftp.drupal.org/files/projects/search_api_solr-8.x-1.x-dev.tar.gz"
SOLR_DOWNLOAD_DIR="/tmp"
SOLR_MODULE_NAME="search_api_solr"
SOLR_VERSION="4.x"
SOLR_CORE_PATH="/var/solr/collection1"

# Check to see if we've already performed this setup.
if [ ! -e "$SOLR_SETUP_COMPLETE_FILE" ]; then
  # Download and expand the Solr module.
  wget -qO- $SOLR_DOWNLOAD | tar xvz -C $SOLR_DOWNLOAD_DIR

  # Copy the Solr configuration into place over the default `collection1` core.
  sudo cp -a $SOLR_DOWNLOAD_DIR/$SOLR_MODULE_NAME/solr-conf/$SOLR_VERSION/. $SOLR_CORE_PATH/conf/

  # Adjust the autoCommit time so index changes are committed in 1s.
  sudo sed -i 's/\(<maxTime>\)\([^<]*\)\(<[^>]*\)/\11000\3/g' $SOLR_CORE_PATH/conf/solrconfig.xml

  # Fix file permissions.
  sudo chown -R solr:solr $SOLR_CORE_PATH/conf

  # Restart Apache Solr.
  #
  # There is some problem with the service command suggested by DrupalVM, hence
  # we use init instead. See:
  # - https://github.com/geerlingguy/ansible-role-solr/pull/81
  # - https://github.com/geerlingguy/drupal-vm/issues/1546
  sudo /etc/init.d/solr stop
  sudo /etc/init.d/solr start

  # Create a file to indicate this script has already run.
  sudo touch $SOLR_SETUP_COMPLETE_FILE
else
  exit 0
fi
