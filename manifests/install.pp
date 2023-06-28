# == Class: ipaclient::install
#
# Install ipaclient
#
class ipaclient::install(
  String $package = undef, # from hiera instead of old-school case() stupidity
){
  package { $package:
    ensure          => installed
  }

}
