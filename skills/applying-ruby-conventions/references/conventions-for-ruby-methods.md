## Conventions for Ruby methods

### Rule: Document every method using a header documenting its parameters and results, using the standard template

#### Example: Correct

```ruby
# Main method purpose and behaviour description.
#
# Parameters::
# * *param1_name* (Param1Type): Description of the parameter 1
# * *param2_name* (Param2Type): Description of the parameter 2 [default = DefaultValue2]
# * *param3_name* (Param3Type): Description of the parameter 3 [default: DefaultValue3]
# Result::
# * Result1Type: Description of the result element 1
# * Result2Type: Description of the result element 2
def my_method(param1_name, param2_name = DefaultValue2, param3_name: DefaultValue3)
  # ...
  [result1, result2]
end
```

#### Rationale

Consistent method documentation makes APIs discoverable and maintainable. The standard template ensures all methods clearly communicate their purpose, parameters, and return values.

### Rule: Limit the scope of methods

Never define public methods if they are not supposed to be used outside of the class.

#### Example: Incorrect

```ruby
class Bag

  # Items is the public API entry point of our Bag
  def items
    if bag_ready?
      internal_list_items
    else
      raise error_for(:not_ready)
    end
  end

  def bag_ready?
    @ready
  end

  def internal_list_items
    @items
  end

  def error_for(code)
    case code
    when :not_ready
      'Bag is not ready'
    end
  end

end
```

#### Example: Correct

```ruby
class Bag

  # Items is the public API entry point of our Bag
  def items
    if bag_ready?
      internal_list_items
    else
      raise error_for(:not_ready)
    end
  end

  private

  def bag_ready?
    @ready
  end

  def internal_list_items
    @items
  end

  def error_for(code)
    case code
    when :not_ready
      'Bag is not ready'
    end
  end

end
```

#### Rationale

Public methods form a contract with external code. Methods that are only used internally should be private to keep the public API minimal and prevent unintended usage patterns that could break during refactoring.
