define mcollective_helper::client_setting ($setting = $title, $target = '/etc/mcollective/client.cfg', $value) {
  validate_re($target, '\/(client.cfg|.mcollective)\Z')
  $regex_escaped_setting = regsubst($setting, '\.', '\\.', 'G') # assume dots are the only regex-unsafe chars in a setting name.
  
  file_line {"mco_client_setting_${title}":
    path  => $target,
    line  => "${setting} = ${value}",
    match => "^ *${regex_escaped_setting} =.*",
  }
}