# Class: centrifydc
#
# This module manages centrifydc
#
class centrifydc (
  $ad_domain    = $domain,
  $ad_admin     = "Your AD Admin account",
  $ad_admin_pw  = "Your AD Admin account password",
  $users_allow  = [],
  $groups_allow = [],
  $user_ignore  = [],
  $group_ignore = []) {
  include centrifydc::params

  $default_users_allow = $centrifydc::params::default_users_allow
  $default_groups_allow = $centrifydc::params::default_groups_allow
  $default_user_ignore = $centrifydc::params::default_user_ignore
  $default_group_ignore = $centrifydc::params::default_group_ignore

  # Install the latest Centrify Express client and join domain
  package { CentrifyDC:
    ensure => latest,
    notify => Exec["adjoin"]
  }

# Install the latest Centrify Express ssh
  package { CentrifyDC-openssh:
    ensure => latest,
    require => Package["CentrifyDC"]
  }

  # Join the domain
  exec { "adjoin":
    path    => $centrifydc::params::exec_path,
    returns => 15,
    command => "adjoin -w -p $ad_admin_pw -u $ad_admin -c 'OU=Linux Servers,DC=redventures,DC=net' -n $centrify_hostname -N $centrify_hostname  ${ad_domain}",
    unless  => "adinfo -d | grep ${ad_domain}",
    notify  => Exec["addns"]
  }

  # Update Active Directory DNS servers with host name
  exec { "addns":
    path        => $centrifydc::params::exec_path,
    returns     => 0,
    command     => 'addns -U -m',
    refreshonly => true,
  }

  file {
    '/etc/centrifydc/centrifydc.conf':
      owner   => root,
      group   => root,
      mode    => 644,
      content => template('centrifydc/centrifydc.conf.erb'),
      require => Package["CentrifyDC"];

    '/etc/nsswitch.conf':
      owner   => root,
      group   => root,
      mode    => 644,
      content => template('centrifydc/nsswitch.conf.erb'),
      require => Package["CentrifyDC","CentrifyDC-openssh"];

    '/etc/centrifydc/ssh/sshd_config':
      owner   => root,
      group   => root,
      mode    => 644,
      content => template('centrifydc/sshd_config.erb'),
      require => Package["CentrifyDC","CentrifyDC-openssh"];


    '/etc/centrifydc/users.allow':
      owner   => root,
      group   => root,
      mode    => 644,
      content => template("centrifydc/users.allow.erb"),
      require => Package["CentrifyDC"];

    '/etc/centrifydc/groups.allow':
      owner   => root,
      group   => root,
      mode    => 644,
      content => template('centrifydc/groups.allow.erb'),
      require => Package['CentrifyDC'];

    '/etc/centrifydc/user.ignore':
      owner   => root,
      group   => root,
      mode    => 644,
      content => template('centrifydc/user.ignore.erb'),
      require => Package['CentrifyDC'];

    '/etc/centrifydc/group.ignore':
      owner   => root,
      group   => root,
      mode    => 644,
      content => template('centrifydc/group.ignore.erb'),
      require => Package['CentrifyDC'];
  }

  service { 'centrifydc':
    ensure     => running,
    require    => Package['CentrifyDC'],
    hasrestart => true,
    subscribe  => [
      File['/etc/centrifydc/centrifydc.conf'],
      File['/etc/centrifydc/users.allow'],
      File['/etc/nsswitch.conf'],
      File['/etc/centrifydc/ssh/sshd_config'],
      File['/etc/centrifydc/groups.allow'],
      File['/etc/centrifydc/user.ignore'],
      File['/etc/centrifydc/group.ignore'],
      Package['CentrifyDC']]
  }


  service { 'centrify-sshd':
    ensure     => running,
    require    => Package['CentrifyDC-openssh'],
    hasrestart => true,
    subscribe  => [
      File['/etc/centrifydc/centrifydc.conf'],
      File['/etc/centrifydc/users.allow'],
      File['/etc/nsswitch.conf'],
      File['/etc/centrifydc/ssh/sshd_config'],
      File['/etc/centrifydc/groups.allow'],
      File['/etc/centrifydc/user.ignore'],
      File['/etc/centrifydc/group.ignore'],
      Package['CentrifyDC-openssh']]
  }

}
