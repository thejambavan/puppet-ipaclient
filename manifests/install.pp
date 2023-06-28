# == Class: ipaclient::install
#
# Install ipaclient
#
class ipaclient::install(
$package = undef # from hiera instead of old-school case() stupidity
) inherits ipaclient::params {
  package { $package:
    ensure          => installed,
    install_options => $package_options,
  }

}
