# This class expects that your activemq.xml file has a line like <import resource="mcollective-broker.xml"/> in it. The base name of the resource is based on the $brokername param below.
class mcollective_helper::activemq::broker (
  # We expect these to always be the same unless you're doing something odd.
  $activemq_confdir = '/etc/activemq',
  $activemq_user = 'activemq',
  # I don't actually know the significance of this, but we go ahead and use it wherever we need a unique keey.
  $brokername = 'mcollective-broker',
  # Whether to encrypt connections.
  $tls = true,
  # What kind of authentication to use. We recommend 'properties'. Can be 'certificate' | 'properties' | 'simple'
  $authentication = 'properties',
  # The names of the collectives you're using.
  $collectives = ['mcollective'],
  # Users should be an array of hashes; each hash must have:
  # 'name' and 'groups'
  # ...and may have:
  # 'password' or 'dn'
  # In default authorization rules, the relevant groups are "admins" and "servers".
  # Admins can issue commands, servers can respond to them.
  $users = [
    { 'name'     => 'mcollective',
      'password' => 'secret',
      'groups'   => ['servers']
    },
    { 'name'     => 'admin',
      'password' => 'secret',
      'groups'   => ['admins']
    }
  ],
  # Required if $tls is true:
  $keystore_password = 'UNSET', # This should be a long string of garbage. Puppet handles all usage of this password, and it does not need to be entered anywhere else by a human.
  $ca = '/var/lib/puppet/ssl/certs/ca.pem', # Default to re-using local copy of Puppet's CA.
  $cert = 'UNSET', # These must be valid Puppet file sources; either local paths or puppet: URLs.
  $private_key = 'UNSET',
  $peers = [ ], # Array of hashes. Each hash must have 'hostname', 'user', and 'password' keys. May use a bare hash instead of array of hashes if you only want one peer. Note that you only need to set up broker-broker connections on one side of the link.
){

  # If we're managing ActiveMQ with Puppet, try to ensure we don't add
  # to the confdir until the package creates it; then, notify activemq
  # whenever the broker element changes.
  if defined(activemq) {
    include activemq
    Package['activemq'] -> Class[$title]
    File["$activemq_confdir/${brokername}.xml"] ~> Service['activemq']
  }

  # Clean the peers to allow for easier singleton peers in hiera data:
  $peers_real = flatten([$peers])
  # Clean $tls to work around widespread Hiera bug
  $tls_real = str2bool("$tls")

  # Set up keystores if necessary
  if $tls_real {
    # Validation and sanity-checks
    if $keystore_password == 'UNSET' or $cert == 'UNSET' or $private_key == 'UNSET' { fail("If ActiveMQ TLS is turned on, the following parameters must be set: ${title}::keystore_password, ${title}::cert, ${title}::private_key, and optionally ${title}::ca.") }
    class {'mcollective_helper::activemq::keystores':
      activemq_confdir  => $activemq_confdir,
      activemq_user     => $activemq_user,
      brokername        => $brokername,
      keystore_password => $keystore_password,
      ca                => $ca,
      cert              => $cert,
      private_key       => $private_key,
    }
  }

  # Main broker config. Uses nearly all parameters.
  file {"${activemq_confdir}/${brokername}.xml":
    ensure  => file,
    mode    => 0600, # If you are using TLS and/or the "simple" authentication method, this file contains secret credentials.
    owner   => $activemq_user,
    group   => $activemq_user,
    content => template("${module_name}/mcollective-broker.xml.erb"),
  }

  # Uses no parameters, currently
  file {"${activemq_confdir}/login.config":
    ensure  => file,
    mode    => 0600,
    owner   => $activemq_user,
    group   => $activemq_user,
    content => template("${module_name}/login.config.erb"),
  }

  # Uses $users parameter.
  file {"${activemq_confdir}/mcollective-groups.properties":
    ensure  => file,
    mode    => 0600,
    owner   => $activemq_user,
    group   => $activemq_user,
    content => template("${module_name}/mcollective-groups.properties.erb"),
  }

  if $authentication == properties {
    # Uses $users parameter.
    file {"${activemq_confdir}/mcollective-password-users.properties":
      ensure  => file,
      mode    => 0600, # This file contains secret credentials if you are using the "properties" authentication method.
      owner   => $activemq_user,
      group   => $activemq_user,
      content => template("${module_name}/mcollective-password-users.properties.erb"),
    }
  }
  if $authentication == certificate {
    # Uses $users parameter.
    file {"${activemq_confdir}/mcollective-certificate-users.properties":
      ensure  => file,
      mode    => 0600,
      owner   => $activemq_user,
      group   => $activemq_user,
      content => template("${module_name}/mcollective-certificate-users.properties.erb"),
    }
  }


}
