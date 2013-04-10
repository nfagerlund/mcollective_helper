class mcollective_helper::activemq::keystores (
  $activemq_confdir = '/etc/activemq',
  $activemq_user    = 'activemq',
  $brokername       = 'mcollective-broker',
  $keystore_password,
  $ca               = '/var/lib/puppet/ssl/certs/ca.pem', # Default to re-using Puppet's CA
  $cert,
  $private_key,
) {

  if defined(activemq) {
    # If we're managing ActiveMQ with Puppet, try to ensure we don't add
    # to the confdir until the package creates it; then, notify activemq
    # whenever the keystore or truststore changes.
    include activemq
    Package['activemq'] -> Class[$title]
    Java_ks['activemq_cert:keystore'] ~> Service['activemq']
    Java_ks['activemq_ca:truststore'] ~> Service['activemq']
  }

  # Maximum security for these credentials
  File {
    owner => root,
    group => root,
    mode  => 0600,
  }
  # There's no automatic mkdir
  file {"${activemq_confdir}/ssl_credentials":
    ensure => directory,
    mode   => 0700,
  }
  # The "don't touch this" sign
  file {"${activemq_confdir}/ssl_credentials/README.txt":
    ensure  => file,
    content => "This directory is managed by Puppet. The credentials in it are used for
ActiveMQ's SSL contexts. They are not used directly, and should remain viewable
by ONLY the root user; Puppet automatically imports them into
${activemq_confdir}/${brokername}.ts and ${activemq_confdir}/${brokername}.ks
for ActiveMQ's use.
",
  }
  # Cert, private key, copy of CA cert
  file {"${activemq_confdir}/ssl_credentials/activemq_certificate.pem":
    ensure => file,
    source => $cert,
  }
  file {"${activemq_confdir}/ssl_credentials/activemq_private.pem":
    ensure => file,
    source => $private_key,
  }
  file {"${activemq_confdir}/ssl_credentials/ca.pem":
    ensure => file,
    source => $ca,
  }

  # Truststore with copy of CA cert
  java_ks { 'activemq_ca:truststore':
    ensure       => latest,
    certificate  => "${activemq_confdir}/ssl_credentials/ca.pem",
    target       => "${activemq_confdir}/${brokername}.ts",
    password     => $keystore_password,
    trustcacerts => true,
    require      => File["${activemq_confdir}/ssl_credentials/ca.pem"],
  }

  # Keystore with ActiveMQ cert and private key
  java_ks { 'activemq_cert:keystore':
    ensure       => latest,
    certificate  => "${activemq_confdir}/ssl_credentials/activemq_certificate.pem",
    private_key  => "${activemq_confdir}/ssl_credentials/activemq_private.pem",
    target       => "${activemq_confdir}/${brokername}.ks",
    password     => $keystore_password,
    require      => [
      File["${activemq_confdir}/ssl_credentials/activemq_private.pem"],
      File["${activemq_confdir}/ssl_credentials/activemq_certificate.pem"]
    ],
  }

  # Don't ensure or manage content of these files, but do manage
  # ownership/mode: these contain important keys, and should be
  # inaccessible to everyone else.
  file {"${activemq_confdir}/${brokername}.ks":
    owner   => $activemq_user,
    group   => $activemq_user,
    mode    => 0600,
    require => Java_ks['activemq_cert:keystore'],
  }
  file {"${activemq_confdir}/${brokername}.ts":
    owner   => $activemq_user,
    group   => $activemq_user,
    mode    => 0600,
    require => Java_ks['activemq_ca:truststore'],
  }
}