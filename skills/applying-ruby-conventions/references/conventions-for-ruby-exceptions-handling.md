## Conventions for Ruby exceptions handling

### Rule: Avoid catching cases of missing or unknown data explicitly

If the data is not in the expected format then a normal exception should be raised, without having to add extra code to support it.
For example when accessing a hash's value that is supposed to exist, don't test for its presence (no need for `next if hash[key].nil?`).

#### Example: Incorrect

```ruby
config = read_config('config.yaml')
raise 'Missing config' if config.nil?
if config.key?(:servers)
  config[:servers].each do |server_config|
    if server_config.key?(:network) && server_config[:network].key?(:ipv4)
      raise 'Missing name' unless server_config.key?(:name)
      puts "#{server_config[:name]} has IP #{server_config[:network][:ipv4]}"
    else
      raise 'Missing network config'
    end
  end
else
  raise 'Missing servers'
end
```

#### Example: Correct

```ruby
read_config('config.yaml')[:servers].each do |server_config|
  puts "#{server_config[:name]} has IP #{server_config[:network][:ipv4]}"
end
```

#### Rationale

Ruby's exception handling is designed to handle unexpected states. Adding explicit nil checks and validation code for data that should always be present creates unnecessary boilerplate. Let Ruby raise natural exceptions when data is malformed, keeping code clean and focused on the happy path.
