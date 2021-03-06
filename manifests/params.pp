# == Class: hiera::params
#
# This class handles OS-specific configuration of the hiera module.  It
# looks for variables in top scope (probably from an ENC such as Dashboard).  If
# the variable doesn't exist in top scope, it falls back to a hard coded default
# value.
#
# === Authors:
#
# Mike Arnold <mike@razorsedge.org>
#
# === Copyright:
#
# Copyright (C) 2013 Mike Arnold, unless otherwise noted.
#
class hiera::params {
  if str2bool($::is_pe) {
    $hiera_yaml = '/etc/puppetlabs/puppet/hiera.yaml'
    $datadir    = '/etc/puppetlabs/puppet/hieradata'
    $owner      = 'pe-puppet'
    $group      = 'pe-puppet'
    $confdir    = '/etc/puppetlabs/puppet'
    $cmdpath    = ['/opt/puppet/bin', '/usr/bin', '/usr/local/bin']

    if $::pe_version and versioncmp($::pe_version, '3.7.0') >= 0 {
      $provider       = 'pe_puppetserver_gem'
      $master_service = 'pe-puppetserver'
    } else {
      $provider       = 'pe_gem'
      $master_service = 'pe-httpd'
    }
  } else {
    if $::pe_server_version {
      $master_service = 'pe-puppetserver'
    } else {
      $master_service = 'puppetmaster'
    }
    if $::puppetversion and versioncmp($::puppetversion, '4.0.0') >= 0 {
      # Configure for AIO packaging.
      $provider = 'puppet_gem'
      $confdir  = '/etc/puppetlabs/code'
      $cmdpath  = ['/opt/puppetlabs/puppet/bin', '/usr/bin', '/usr/local/bin']
    } else {
      $provider = 'gem'
      $confdir  = '/etc/puppet'
      $cmdpath  = ['/usr/bin', '/usr/local/bin']
    }
    if $::pe_server_version {
      $owner    = 'pe-puppet'
      $group    = 'pe-puppet'
    } else {
      $owner    = 'puppet'
      $group    = 'puppet'
    }
    $hiera_yaml = "${confdir}/hiera.yaml"
    $datadir    = "${confdir}/hieradata"
  }
}
