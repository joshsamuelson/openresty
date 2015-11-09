class openresty::install ( $openresty_version = '1.9.3.1') {
  # Debian Dependencies
  $debian_deps = [
                  'libreadline-dev',
                  'libncurses5-dev',
                  'libpcre3-dev',
                  'libssl-dev',
                  'ruby-dev',
                  'gcc',
                  'perl',
                  'make',
                  'build-essential'
                ]
  ensure_packages($debian_deps, {
    ensure => present,
    before => Exec['configure openresty']
  })
  ensure_packages('fpm',{
    ensure => present,
    provider => 'gem',
    before => Exec['package openresty'],
  })

  $openresty_file = "ngx_openresty-${openresty_version}"
  $openresty_package = regsubst($openresty_file,'_','-')

  staging::deploy { "${openresty_file}.tar.gz":
    source => "https://openresty.org/download/${openresty_file}.tar.gz",
    target => '/usr/src',
    notify => Exec['configure openresty'],
  }

  exec { 'configure openresty':
    command => "/usr/src/${openresty_file}/configure",
    creates => "/usr/src/${openresty_file}/Makefile",
    path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    notify => Exec['build openresty'],
  }

  exec { 'build openresty':
    command => 'make ; make install',
    creates => '/usr/local/openresty',
    cwd => "/usr/src/${openresty_file}/",
    path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    notify => Exec['package openresty'],
  }

  exec { 'package openresty':
    command => "fpm -s dir -t deb -n ${openresty_package} /usr/src/${openresty_file}",
    creates => "/usr/src/${openresty_file}/${openresty_package}_1.0_${::architecture}.deb",
    cwd => "/usr/src/${openresty_file}/",
    path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    notify => Package[$openresty_file],
  }

  file { '/etc/init.d/openresty':
    ensure => file,
    source => 'puppet:///modules/openresty/openresty.init.d.script',
    mode   => '0755',
    require => Package[$openresty_file],
  }

  package { $openresty_file:
    ensure => present,
    provider => 'dpkg',
    source => "/usr/src/${openresty_file}/${openresty_package}_1.0_${::architecture}.deb",
  }

  service { 'openresty':
    ensure => running,
    enable => true,
    require => File['/etc/init.d/openresty'],
  }
}
