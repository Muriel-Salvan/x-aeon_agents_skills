## Conventions for all Ruby files

### Rule: Never add frozen_string_literal comment in files

#### Example: Incorrect

```ruby
# frozen_string_literal: true
```

#### Rationale

The frozen_string_literal magic comment is not needed in modern Ruby versions and should be removed when found.
