module Puppet::Parser::Functions
  newfunction(:get_member_of_unknown_hash, :type => :rvalue, :doc => <<-EOS
Given an array of anonymous hashes, this function lets you locate a hash by the
value of one of its keys, then get the value of another key from that hash. In
the case of multiple matches, we return the desired value from the final match.
Returns an empty string if no matches are found.

*Example:*

    $users = [
      { 'name'     => 'mcollective',
        'password' => 'secret',
        'groups'   => ['servers']
      },
      { 'name'     => 'admin',
        'password' => 'secret',
        'groups'   => ['admins']
      }
    ]

    get_member_of_unknown_hash( $users, 'name', 'mcollective', 'password' )

Would return:

    'secret'
EOS
  ) do |arguments|

    if (arguments.size != 4) then
      raise(Puppet::ParseError, "get_member_of_unknown_hash(): Wrong number of arguments "+
        "given #{arguments.size} for 4")
    end

    ary = arguments[0]
    index_key = arguments[1]
    index_value = arguments[2]
    desired_key = arguments[3]
    result = ''

    if ary.class == Array
      ary.each do |hsh|
        next unless hsh.class == Hash
        next unless hsh[index_key]
        if hsh[index_key] == index_value
          next unless hsh[desired_key]
          result = hsh[desired_key]
        end
      end
    end

    result
  end
end