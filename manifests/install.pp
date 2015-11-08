class openresty::install ( $openresty_version = '1.9.3.1') {
  # Debian Dependencies
  $debian_deps = [
                  'libreadline-dev',
                  'libncurses5-dev',
                  'libpcre3-dev',
                  'libssl-dev',
                  'perl',
                  'make',
                  'build-essential'
                ]
  ensure_packages($debian_deps, {
    ensure => present,
    before => Exec['configure openresty']
  })

  $openresty_file = "ngx_openresty-${openresty_version}"

  staging::deploy { "${openresty_file}.tar.gz":
    source => "https://openresty.org/download/${openresty_file}.tar.gz",
    target => '/usr/src',
    notify => Exec['configure openresty'],
  }

  exec { 'configure openresty':
    command => "/usr/src/${openresty_file}/configure",
    creates => "/usr/src/${openresty_file}/Makefile",
    path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    notify => Exec['install openresty'],
  }

  exec { 'install openresty':
    command => 'make ; make install',
    creates => '/usr/local/openresty',
    cwd => "/usr/src/${openresty_file}/",
    path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
  }

  file { '/etc/init.d/openresty':
    ensure => file,
    source => 'puppet:///modules/openresty/openresty.init.d.script',
    mode   => '0755',
    require => Exec['install openresty'],
  }

  service { 'openresty':
    ensure => running,
    enable => true,
    require => File['/etc/init.d/openresty'],
  }
}
