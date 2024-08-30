# @summary This module manages prometheus beanstalkd_exporter
# @param arch
#  Architecture (amd64 or i386)
# @param bin_dir
#  Directory where binaries are located
# @param config
#  Path to configuration file that stores beanstalkd address
# @param mapping_config
#  Path to configuration file with tubes mappings (not implemented)
# @param beanstalkd_address
#  Address of beanstalkd, defaults to localhost
# @param exporter_listen
#  Address to bind beanstalkd_exporter to. Default is different than upstream (*:9371)
# @param download_extension
#  Extension for the release binary archive
# @param download_url
#  Complete URL corresponding to the where the release binary archive can be downloaded
# @param download_url_base
#  Base URL for the binary archive
# @param extra_groups
#  Extra groups to add the binary user to
# @param extra_options
#  Extra options added to the startup command
# @param group
#  Group under which the binary is running
# @param init_style
#  Service startup scripts style (e.g. rc, upstart or systemd)
# @param install_method
#  Installation method: url or package (only url is supported currently)
# @param manage_group
#  Whether to create a group for or rely on external code for that
# @param manage_service
#  Should puppet manage the service? (default true)
# @param manage_user
#  Whether to create user or rely on external code for that
# @param os
#  Operating system (linux is the only one supported)
# @param package_ensure
#  If package, then use this for package ensure default 'latest'
# @param package_name
#  The binary package name - not available yet
# @param purge_config_dir
#  Purge config files no longer generated by Puppet
# @param restart_on_change
#  Should puppet restart the service on configuration change? (default true)
# @param service_enable
#  Whether to enable the service from puppet (default true)
# @param service_ensure
#  State ensured for the service (default 'running')
# @param service_name
#  Name of the beanstalkd exporter service (default 'beanstalkd_exporter')
# @param user
#  User which runs the service
# @param version
#  The binary release version
# @param proxy_server
#  Optional proxy server, with port number if needed. ie: https://example.com:8080
# @param proxy_type
#  Optional proxy server type (none|http|https|ftp)
class prometheus::beanstalkd_exporter (
  String $download_extension,
  Prometheus::Uri $download_url_base,
  Array $extra_groups,
  String[1] $group,
  String[1] $package_ensure,
  String[1] $package_name,
  String[1] $service_name,
  String[1] $user,
  String[1] $config,
  String[1] $mapping_config,
  String[1] $beanstalkd_address,
  String[1] $exporter_listen,
  # renovate: depName=messagebird/beanstalkd_exporter
  String[1] $version                                         = '1.0.5',
  Boolean $purge_config_dir                                  = true,
  Boolean $restart_on_change                                 = true,
  Boolean $service_enable                                    = true,
  Stdlib::Ensure::Service $service_ensure                    = 'running',
  Prometheus::Initstyle $init_style                          = $prometheus::init_style,
  Prometheus::Install $install_method                        = $prometheus::install_method,
  Boolean $manage_group                                      = true,
  Boolean $manage_service                                    = true,
  Boolean $manage_user                                       = true,
  String[1] $os                                              = downcase($facts['kernel']),
  Optional[String[1]] $extra_options                         = undef,
  Variant[Undef,String] $download_url                        = undef,
  String[1] $arch                                            = $prometheus::real_arch,
  Stdlib::Absolutepath $bin_dir                              = $prometheus::bin_dir,
  Boolean $export_scrape_job                                 = false,
  Optional[Stdlib::Host] $scrape_host                        = undef,
  Stdlib::Port $scrape_port                                  = 8080,
  String[1] $scrape_job_name                                 = 'beanstalkd',
  Optional[Hash] $scrape_job_labels                          = undef,
  Optional[String[1]] $proxy_server                          = undef,
  Optional[Enum['none', 'http', 'https', 'ftp']] $proxy_type = undef,
) inherits prometheus {
  # Download url differs between 1.0.0 and 1.0.1 onwards
  if( versioncmp($version, '1.0.0') < 1 ) {
    $real_download_url = pick($download_url,"${download_url_base}/download/${version}/${package_name}-${version}.${os}-${arch}.${download_extension}")
    $options = "-listen-address ${exporter_listen} -config ${config} -mapping-config ${mapping_config} ${extra_options}"
    $real_file_ensure = 'file'
  } else {
    $real_download_url = pick($download_url,"${download_url_base}/download/${version}/${package_name}-${version}.${os}-${arch}")
    $options = "-web.listen-address ${exporter_listen} -beanstalkd.address ${beanstalkd_address} ${extra_options}"
    $real_file_ensure = 'absent'
  }

  $notify_service = $restart_on_change ? {
    true    => Service[$service_name],
    default => undef,
  }

  file { $config:
    ensure  => $real_file_ensure,
    content => $beanstalkd_address,
    before  => Prometheus::Daemon[$service_name],
  }

  file { $mapping_config:
    ensure => $real_file_ensure,
    before => Prometheus::Daemon[$service_name],
  }

  prometheus::daemon { $service_name:
    install_method     => $install_method,
    version            => $version,
    download_extension => $download_extension,
    os                 => $os,
    arch               => $arch,
    real_download_url  => $real_download_url,
    bin_dir            => $bin_dir,
    notify_service     => $notify_service,
    package_name       => $package_name,
    package_ensure     => $package_ensure,
    manage_user        => $manage_user,
    user               => $user,
    extra_groups       => $extra_groups,
    group              => $group,
    manage_group       => $manage_group,
    purge              => $purge_config_dir,
    options            => $options,
    init_style         => $init_style,
    service_ensure     => $service_ensure,
    service_enable     => $service_enable,
    manage_service     => $manage_service,
    export_scrape_job  => $export_scrape_job,
    scrape_host        => $scrape_host,
    scrape_port        => $scrape_port,
    scrape_job_name    => $scrape_job_name,
    scrape_job_labels  => $scrape_job_labels,
    proxy_server       => $proxy_server,
    proxy_type         => $proxy_type,
  }
}
