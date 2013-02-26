class mcollective_helper (
  $puppet_ssldir = '/var/lib/puppet/ssl', # appropriate for RedHat-like, change for Debian-like
  $activemq_users = [
    { 'name'     => 'mcollective',
      'password' => 'secret',
      'groups'   => ['servers']
    },
    { 'name'     => 'admin',
      'password' => 'secret',
      'groups'   => ['admins']
    }
  ],

){
  # stub class for data
}