## Conventions for Ruby strings

### Rule: Prefer using HEREDOC strings for multiline strings instead of Array or repetitive statements

#### Example: Incorrect

```ruby
puts 'Statistics:'
puts "* Number of elements: #{nbr}"
puts "* Average value: #{average}"
puts "* Sum: #{sum}"
puts
```

#### Example: Correct

```ruby
puts <<~EO_Output
  Statistics:
  * Number of elements: #{nbr}
  * Average value: #{average}
  * Sum: #{sum}
EO_Output
```

#### Rationale

HEREDOC syntax provides cleaner, more readable multiline strings that preserve formatting naturally. It reduces repetitive calls and makes the output structure visually clear in the code.
