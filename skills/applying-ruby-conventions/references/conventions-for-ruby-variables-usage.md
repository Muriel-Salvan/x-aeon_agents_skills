## Conventions for Ruby variables usage

### Rule: Avoid defining local variables that are used only once

Try to use the variable value directly where it is needed.

#### Example: Incorrect

```ruby
src_path = '/src_dir/my_file.txt'
base_name = File.basename(src_path)
dst_dir_name = '/dst_dir'
dst_path = dst_dir_name + '/' + base_name
FileUtils.mv src_path, dst_path
```

#### Example: Correct

```ruby
src_path = '/src_dir/my_file.txt'
FileUtils.mv src_path, "/dst_dir/#{File.basename(src_path)}"
```

#### Rationale

Single-use variables add unnecessary cognitive overhead and clutter. Inline expressions that are only used once make the code flow clearer and reduce the number of names readers need to track.

### Rule: Prefer using chained calls over explicit variable definitions between steps

#### Example: Incorrect

```ruby
all_items = query('SELECT * FROM TABLE')
filtered_items = all_items.select { |e| e.country == 'ES' }
grouped_items = filtered_items.group_by { |e| e.city }
cities = grouped_items.map { |city, city_items| "#{city} has #{city_items.size} items" }
output = cities.join(', ')
puts output
```

#### Example: Correct

```ruby
puts(
  query('SELECT * FROM TABLE').
    select { |e| e.country == 'ES' }.
    group_by { |e| e.city }.
    map { |city, city_items| "#{city} has #{city_items.size} items" }.
    join(', ')
)
```

#### Rationale

Method chaining creates a clear pipeline of data transformations that reads naturally from left to right. It eliminates intermediate variables that serve no purpose beyond holding temporary state, making the data flow more explicit.

### Rule: Avoid using global variables

#### Example: Incorrect

```ruby
$my_var = 42
```

#### Example: Correct

```ruby
my_var = 42
```

#### Rationale

Global variables create hidden dependencies and make code difficult to reason about and test. Local variables or constants provide the same functionality with clear, limited scope.

### Rule: Limit the scope of variables

Do not use instance variables when local variables are enough

#### Example: Incorrect

```ruby
class MyClass

  attr_reader :states

  def initialize
    @states = []
  end

  def check_changes
    @changes = State.get_changes
    @changes = 'No change' if @changes.empty?
    @states << @changes
  end

end
```

#### Example: Correct

```ruby
class MyClass

  attr_reader :states

  def initialize
    @states = []
  end

  def check_changes
    changes = State.get_changes
    changes = 'No change' if changes.empty?
    @states << changes
  end

end
```

#### Rationale

Limiting variable scope to the minimum necessary reduces side effects and makes code easier to understand and refactor. Instance variables persist state that may not need to be shared across method calls.
