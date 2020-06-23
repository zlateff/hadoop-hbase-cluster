include base
include hadoop
include hbase
#include hive
#include phoenix
#include spark
include avahi

file { 
    "/etc/environment":
      ensure  => present,
      source => "/vagrant/modules/base/files/env_var",
      mode => "0755",
      owner => root,
      group => root,
  }
