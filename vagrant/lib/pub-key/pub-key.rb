def find_pub_key()
  types = ['id_rsa.pub', 'id_dsa.pub']
  types.each do | key |
    key_path = File.expand_path('~/.ssh/'+key)
    if File.exist?(key_path)
      return key_path
    end
  end

  puts "No public SSH key found. Try running `ssh-keygen -t rsa`"
  return false

end
