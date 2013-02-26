class mcollective_helper::server::data (
  $puppet_vardir = '/var/lib/puppet'
){

# facts and stuff
  mcollective_helper::setting {
    'identity':
      value => $::fqdn;
    'factsource':
      value => 'yaml';
    'plugin.yaml':
      value => '/etc/mcollective/facts.yaml';
    'classesfile':
      value => "${puppet_vardir}/classes.txt";
  }
  file{"/etc/mcollective/facts.yaml":
     owner    => root,
     group    => root,
     mode     => 400,
     loglevel => debug,  # this is needed to avoid it being logged and reported on every run
     # avoid including highly-dynamic facts as they will cause unnecessary template writes
     content  => inline_template("<%= scope.to_hash.reject { |k,v| k.to_s =~ /(uptime_seconds|timestamp|free)/ }.to_yaml %>"),
  }

}