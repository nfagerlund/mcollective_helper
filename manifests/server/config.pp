# Still only doing a single activemq server.
class mcollective_helper::server::config (
  $activemq_server,
  $ca = "${puppet_ssldir}/certs/ca.pem", # default to re-using Puppet cert infrastructure for middleware connection...
  $cert = "${puppet_ssldir}/certs/${::clientcert}.pem", # ...but OK to use local path or puppet:/// URL.
  $private_key = "${puppet_ssldir}/private_keys/${::clientcert}.pem",
  $ssl_server_private, # Local path or puppet:/// URL.
  $ssl_server_public, # Local path or puppet:/// URL.
  $ssl_client_cert_dir, # Local path or puppet:/// URL.
  $activemq_user = 'mcollective',
  $activemq_password = 'UNSET', # OK to leave unset; will auto-discover if you have mcollective_helper::activemq_users set up.
  $main_collective = 'mcollective',
  $collectives = ['mcollective'],
  $activemq_tls = true, # sloppy bool: accepts real bools, string bools, and 0/1.
  $mcollectived_user = 'root', # In case mcollective isn't running as root.
  $mcollective_confdir = '/etc/mcollective', # shouldn't need to change this
) inherits mcollective_helper { # Inheriting for params

  # munge parameters
  $collectives_real = unique( flatten( [$collectives, $main_collective] ) ) # Make sure $main_collective is included.
  $activemq_tls_real = str2bool("$activemq_tls") # Get real bool from sloppy bool.
  $discovered_activemq_password = get_member_of_unknown_hash($activemq_users, 'name', $activemq_user, 'password') # $activemq_users comes from class mcollective_helper's params.
  # Attempt to auto-discover ActiveMQ password, if necessary.
  $activemq_password_real = $activemq_password ? {
    'UNSET' => $discovered_activemq_password ? {
                 ''      => 'UNSET',
                 default => $discovered_activemq_password,
               },
    default => $activemq_password,
  }

  # The files we're managing are fairly sensitive, inc. private keys.
  File {
    ensure => file,
    mode   => 0640,
    owner  => $mcollectived_user,
    group  => $mcollectived_user,
  }
  # Sync credentials if necessary
  $credentials_dir = "${mcollective_confdir}/credentials"
  file {$credentials_dir:
    ensure => directory,
    mode   => 0750,
  }
  if $ca =~ /\Apuppet:/ {
    $ca_real = "${credentials_dir}/ca.pem"
    file {$ca_real: source => $ca, }
  }
  else { $ca_real = $ca }
  
  if $cert =~ /\Apuppet:/ {
    $cert_real = "${credentials_dir}/cert.pem"
    file {$cert_real: source => $cert, }
  }
  else { $cert_real = $cert }
  
  if $private_key =~ /\Apuppet:/ {
    $private_key_real = "${credentials_dir}/private_key.pem"
    file {$private_key_real: source => $private_key, }
  }
  else { $private_key_real = $private_key }
  
  if $ssl_server_private =~ /\Apuppet:/ {
    $ssl_server_private_real = "${credentials_dir}/ssl_server_private.pem"
    file {$ssl_server_private_real: source => $ssl_server_private, }
  }
  else { $ssl_server_private_real = $ssl_server_private }
  
  if $ssl_server_public =~ /\Apuppet:/ {
    $ssl_server_public_real = "${credentials_dir}/ssl_server_public.pem"
    file {$ssl_server_public_real: source => $ssl_server_public, }
  }
  else { $ssl_server_public_real = $ssl_server_public }
  
  if $ssl_client_cert_dir =~ /\Apuppet:/ {
    $ssl_client_cert_dir_real = "${credentials_dir}/ssl_client_cert_dir.pem"
    file {$ssl_client_cert_dir_real: source => $ssl_client_cert_dir, }
  }
  else { $ssl_client_cert_dir_real = $ssl_client_cert_dir }

  # handle odd server.cfg locations
  Mcollective_helper::Setting {
    target => "${mcollective_confdir}/server.cfg",
  }

  # ssl security plugin settings
  mcollective_helper::setting {
    'securityprovider':
      value => 'ssl';
    'plugin.ssl_server_private':
      value => $ssl_server_private_real;
    'plugin.ssl_server_public':
      value => $ssl_server_public_real;
    'plugin.ssl_client_cert_dir':
      value => $ssl_client_cert_dir_real;
  }

  # activemq connector settings
  mcollective_helper::setting {
    'connector':
      value => 'activemq';
    'direct_addressing':
      value => 'yes';
  # We don't currently support multiple servers.
    'plugin.activemq.pool.size':
      value => '1';
    'plugin.activemq.pool.1.host':
      value => $activemq_server;
    'plugin.activemq.pool.1.port':
      value => $activemq_tls_real ? {
        true  => '61614',
        false => '61613',
      };
    'plugin.activemq.pool.1.user':
      value => $activemq_user;
    'plugin.activemq.pool.1.password':
      value => $activemq_password_real;
  # activemq tls
    'plugin.activemq.pool.1.ssl':
      value => $activemq_tls_real ? {
        true  => '1',
        false => '0',
      };
    'plugin.activemq.pool.1.ssl.ca':
      value => $ca_real;
    'plugin.activemq.pool.1.ssl.key':
      value => $private_key_real;
    'plugin.activemq.pool.1.ssl.cert':
      value => $cert_real;
  }

  # collectives
  mcollective_helper::setting {
    'main_collective':
      value => $main_collective;
    'collectives':
      value => join($collectives_real, ',');
  }

  
}