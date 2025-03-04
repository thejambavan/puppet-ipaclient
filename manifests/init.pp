# == Class: ipaclient
#
# You can use this class to configure your servers to use FreeIPA
#
# === Parameters
#
# Minimum Parameters (if relying on DNS discovery):
#   password
#
# All Parameters:
#
# $automount::             Enable automount
#                          Default: false
#
# $automount_location::    Automounter location
#
# $automount_server::      Automounter server
#
# $domain::                Domain, e.g. pixiedust.com
#
# $fixed_primary::         Used a fixed primary
#                          Default: false
#
# $force::                 Enable "forced" installation mode
#                          Default: false
#
# $installer::             IPA install command
#
# $mkhomedir::             Automatically make /home/<user> or not
#                          Default: true
#
# $needs_sudo_config       Manually configure sudo? (Boolean)
#
# $ntp::                   Manage and configure ntpd?
#                          Default: true
#
# $options::               Additional command-line options to pass directly to
#                          installer
#
# $package::               Package to install
#
# $password::              One-time password, or registration user's password
#
# $principal::             Kerberos principal when not using one-time passwords
#
# $realm::                 Realm, e.g. PIXIEDUST.COM
#
# $server::                Can be array or string of IPA servers
#
# $ssh::                   Enable SSH Integation
#                          Default: true
#
# $sshd::                  Enable SSHD Integration
#                          Default: true
#
# $subid::                 Use SSSD as subid provider
#                          Default: false
#
# $sudo::                  Enable sudoers management
#                          Default: true
#
# $hostname::              Client FQDN
#
# $force_join::            Forces domain joining if host already joined once
#
# === Examples
#
# Discovery register example:
#
#  class { 'ipaclient':
#       password         => "rainbows"
#  }
#
# More complex:
#
#  class { 'ipaclient':
#       mkhomedir          => false,
#       automount          => true,
#       automount_location => "home",
#       password           => "unicorns",
#       domain             => "pixiedust.com",
#       realm              => "PIXEDUST.COM",
#       server             => ["ipa01.pixiedust.com", "ipa02.pixiedust.com"]
#  }
#
# === Authors
#
# Stephen Benjamin <stephen@bitbin.de>
#
# === Copyright
#
# Copyright 2014 Stephen Benjamin.
# Released under the MIT License. See LICENSE for more information
#
class ipaclient (
  $automount          = $ipaclient::params::automount,
  $automount_location = $ipaclient::params::automount_location,
  $automount_server   = $ipaclient::params::automount_server,
  $domain             = $ipaclient::params::domain,
  $fixed_primary      = $ipaclient::params::fixed_primary,
  $force              = $ipaclient::params::force,
  $installer          = $ipaclient::params::installer,
  $mkhomedir          = $ipaclient::params::mkhomedir,
  $needs_sudo_config  = $ipaclient::params::needs_sudo_config,
  $ntp                = $ipaclient::params::ntp,
  $options            = $ipaclient::params::options,
  $package            = $ipaclient::params::package,
  $package_options    = $ipaclient::params::package_options,
  $password           = $ipaclient::params::password,
  $principal          = $ipaclient::params::principal,
  $realm              = $ipaclient::params::realm,
  $server             = $ipaclient::params::server,
  $ssh                = $ipaclient::params::ssh,
  $sshd               = $ipaclient::params::sshd,
  $subid              = $ipaclient::params::subid,
  $sudo               = $ipaclient::params::sudo,
  $hostname           = $ipaclient::params::hostname,
  $force_join         = $ipaclient::params::force_join
) inherits ipaclient::params {

  package { $package:
    ensure => installed,
    install_options => $package_options,
  }

  if !str2bool($::ipa_enrolled) {
    if empty($password) {
      fail('Require at least a join password')
    } else {
      # Build the installer command:

      $opt_password = ['--password', $password]

      if $server =~ Array[Any]{
        # Transform ['a','b'] -> ['--server','a','--server','b']
        $opt_server = split(join(prefix($server, '--server|'), '|'), '\|')
      } elsif !empty($server) {
        $opt_server = ['--server' ,$server]
      } else {
        $opt_server = ''
      }

      if $domain {
        $opt_domain = ['--domain', $domain]
      } else {
        $opt_domain = ''
      }

      if $hostname {
        $opt_hostname = ['--hostname', $hostname]
      } else {
        $opt_hostname = ''
      }

      if $realm {
        $opt_realm = ['--realm', $realm]
      } else {
        $opt_realm = ''
      }

      if $principal {
        $opt_principal = ['--principal', "${principal}@${realm}"]
      } else {
        $opt_principal = ''
      }

      if !str2bool($ssh) {
        $opt_ssh = '--no-ssh'
      } else {
        $opt_ssh = ''
      }

      if !str2bool($sshd) {
        $opt_sshd = '--no-sshd'
      } else {
        $opt_sshd = ''
      }

      if str2bool($fixed_primary) {
        $opt_fixed_primary = '--fixed-primary'
      } else {
        $opt_fixed_primary = ''
      }

      if str2bool($mkhomedir) {
        $opt_mkhomedir = '--mkhomedir'
      } else {
        $opt_mkhomedir = ''
      }

      if !str2bool($ntp) {
        $opt_ntp = '--no-ntp'
      } else {
        $opt_ntp = ''
      }

      if str2bool($force) {
        $opt_force = '--force'
      } else {
        $opt_force = ''
      }

      if !empty($::ipa_client_version) and
         versioncmp($::ipa_client_version, "4.9.10") >= 0 and
         str2bool($subid) {
        $opt_subid = '--subid'
      } else {
        $opt_subid = ''
      }

      if !str2bool($sudo) {
        $opt_sudo = '--no-sudo'
      } else {
        $opt_sudo = ''
      }
      
      if str2bool($force_join) {
        $opt_force_join = '--force-join'
      } else {
        $opt_force_join = ''
      }

      # Flatten the arrays, delete empty options, and shellquote everything
      $command = shellquote(delete(flatten([$installer,$opt_realm,$opt_password,
                            $opt_principal,$opt_mkhomedir,$opt_domain,$opt_hostname,
                            $opt_server,$opt_fixed_primary,$opt_ssh,$opt_sshd,$opt_ntp,
                            $opt_sudo,$opt_subid,$opt_force,$opt_force_join,$options,
                            '--unattended']), ''))

      # Make sure we can collect the `ipa_client_version` fact first
      # Makes us run twice, though :(
      if !empty($::ipa_client_version) {
        exec { 'ipa_installer':
          command => $command,
          unless  => "/usr/sbin/ipa-client-install -U 2>&1 \
            | /bin/grep -q 'already configured'",
          require => Package[$package],
        }
      }

      $installer_resource = Exec['ipa_installer']

      # Include debian fixes since the installer doesn't properly
      # configure ssh and mkhomedir
      if ($::osfamily == 'Debian') {
        class { 'ipaclient::debian_fixes':
          require => $installer_resource,
        }
      }
    }
  }

  if (str2bool($sudo) and str2bool($needs_sudo_config)) {
    # If user didn't specify a server, use the fact.  Otherwise pass in
    # the first value of server parameter
    if empty($server) {
      $sudo_server = $::ipa_server
    } elsif $server =~ Array[Any] {
      $sudo_server = $server[0]
    } else {
      $sudo_server = $server
    }

    # If user didn't specify a domain, use the fact.
    if empty($domain) {
      $sudo_domain = $::ipa_domain
    } else {
      $sudo_domain = $domain
    }

    class { 'ipaclient::sudoers':
      server  => $sudo_server,
      domain  => $sudo_domain,
      require => $installer_resource,
    }
  }

  if str2bool($automount) {
    class { 'ipaclient::automount':
        location => $automount_location,
        server   => $automount_server,
        require  => $installer_resource,
    }
  }
}

