# == Class: ipaclient::params
#
# Default parameters for the ipaclient module
#
class ipaclient::params {

  $server         = ''
  $hostname       = undef
  $domain         = undef
  $realm          = undef
  $principal      = undef
  $password       = ''
  $ntp_server     = ''
  $ssh            = true
  $sshd           = true
  $automount      = false
  $mkhomedir      = true
  $subid          = false
  $sudo           = true
  $fixed_primary  = false
  $options        = ''
  $installer      = '/usr/sbin/ipa-client-install'
  $automount_location = ''
  $automount_server   = ''
  $ntp            = true
  $force          = false
  $sssd_sudo_cache_timeout     = ''
  $sssd_sudo_full_refresh      = ''
  $sssd_sudo_smart_refresh     = ''
  $sssd_default_domain_suffix  = ''
  $force_join     = false
  $package_options = []

  # Determine if client needs manual sudo configuration or not
  # RHEL <=6.5 requires manual configuration
  # RHEL 6.6 includes automatic sudo configuration
  # RHEL 7.0 requires manual confifuration
  # RHEL >=7.1 includes automatic sudo configuration
  case $facts['os']['family'] {
    'RedHat': {
      case $facts['os']['name'] {
        'Fedora': {
          if (versioncmp($facts['os']['release'], '21') >= 0) {
            $needs_sudo_config = false
          } else {
            $needs_sudo_config = true
          }
        }
        default: {
          if (versioncmp($facts['os']['release'], '6.6') >= 0) {
            if (versioncmp($facts['os']['release'], '7.0') == 0) {
              $needs_sudo_config = true
            } else {
              $needs_sudo_config = false
            }
          } else {
            $needs_sudo_config = true
          }
        }
      }
    }
    'Debian': {
      case $facts['os']['name'] {
        'Ubuntu': {
          if (versioncmp($facts['os']['release'], '15.04') > 0) {
            $needs_sudo_config = false
          } else {
            $needs_sudo_config = true
          }
        }
        default: {
          $needs_sudo_config = true
        }
      }
    }
    default: {
      fail("This module does not support operatingsystem ${::operatingsystem}")
    }
  }

  # Name of IPA package to install
  case $facts['os']['family'] {
    'RedHat': {
      case $facts['os']['name'] {
        'fedora': {
          $package = 'freeipa-client'
        }
        default: {
          $package = 'ipa-client'
        }
      }
    }
    'Debian': {
        $package = 'freeipa-client'
    }
    default: {
      fail("This module does not support operatingsystem ${::operatingsystem}")
    }
  }
}

