define mcollective_helper::setting ($setting = $title, $target = '/etc/mcollective/server.cfg', $value) {
  validate_re($target, '\/server.cfg\Z')
  $regex_escaped_setting = regsubst($setting, '\.', '\\.', 'G') # assume dots are the only regex-unsafe chars in a setting name.
  
  file_line {"mco_setting_${title}":
    path  => $target,
    line  => "${setting} = ${value}",
    match => "^ *${regex_escaped_setting} =.*",
  }
}