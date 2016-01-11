# == Class: hiera::eyaml
#
# This class installs and configures hiera-eyaml
#
# === Authors:
#
# Terri Haber <terri@puppetlabs.com>
#
# === Copyright:
#
# Copyright (C) 2014 Terri Haber, unless otherwise noted.
#
class hiera::eyaml {
  $provider      = $hiera::provider
  $owner         = $hiera::owner
  $group         = $hiera::group
  $cmdpath       = $hiera::cmdpath
  $confdir       = $hiera::confdir
  $create_keys   = $hiera::create_keys
  $eyaml_version = $hiera::eyaml_version
  $gem_source    = $hiera::gem_source

  $package_ensure = $eyaml_version ? {
    undef   => 'installed',
    default => $eyaml_version,
  }
  if $provider == 'pe_puppetserver_gem' {
    Exec {
      path => [
        '/opt/puppet/bin',
        '/usr/bin',
        '/bin',
      ],
    }

    $hiera_package_depedencies = [
      Exec['install ruby gem hiera-eyaml'],
      Exec['install puppetserver gem hiera-eyaml'],
    ]

    # The puppetserver gem wouldn't install the commandline util, so we do
    # that here (PUP-1073)
    #BUG This can't actually update the gem version if already installed.
    if $eyaml_version and $eyaml_version =~ /^\d+\.\d+\.\d+$/ {
      $gem_flag = "--version ${eyaml_version}"
    } else {
      $gem_flag = undef
    }

    exec { 'install ruby gem hiera-eyaml':
      command => "gem install hiera-eyaml ${gem_flag}",
      creates => '/opt/puppet/bin/eyaml',
    }

    exec { 'install puppetserver gem hiera-eyaml':
      command => "puppetserver gem install hiera-eyaml ${gem_flag}",
      creates => '/var/opt/lib/pe-puppet-server/jruby-gems/bin/eyaml',
      notify  => Service[$hiera::master_service],
    }
  } elsif $provider == 'puppetserver_gem' {
    $hiera_package_depedencies = [
      Package['hiera-eyaml'],
      Package['puppetserver hiera-eyaml'],
    ]
    package { 'puppetserver hiera-eyaml':
      ensure   => $package_ensure,
      name     => 'hiera-eyaml',
      provider => $provider,
      source   => $gem_source,
    }
    package { 'hiera-eyaml':
      ensure   => $package_ensure,
      provider => 'puppet_gem',
      source   => $gem_source,
    }
  } else {
    $hiera_package_depedencies = Package['hiera-eyaml']
    package { 'hiera-eyaml':
      ensure   => $package_ensure,
      provider => $provider,
      source   => $gem_source,
    }
  }

  File {
    owner => $owner,
    group => $group,
  }

  file { "${confdir}/keys":
    ensure => directory,
  }

  if ( $create_keys == true ) {
    exec { 'createkeys':
      user    => $owner,
      cwd     => $confdir,
      command => 'eyaml createkeys',
      path    => $cmdpath,
      creates => "${confdir}/keys/private_key.pkcs7.pem",
      require => [ $hiera_package_depedencies, File["${confdir}/keys"] ],
    }

    file { "${confdir}/keys/private_key.pkcs7.pem":
      ensure  => file,
      mode    => '0600',
      require => Exec['createkeys'],
    }

    file { "${confdir}/keys/public_key.pkcs7.pem":
      ensure  => file,
      mode    => '0644',
      require => Exec['createkeys'],
    }
  }
}
