# Emery

Emery is a type safety library for Ruby. It provides a way to define types and serialize/deserialize them to/from JSON with type certainty and safety

## Basic Usage Example

Here's basic example of Emery type checking:
```ruby
require 'emery'

my_var = T.check(T.array(String), ["the string"])
# my_var is ["the string"]

my_var = T.check(T.array(String), "the string")
# Throws: Value '"the string"' type is String - Array is required
```

Here's type safe JSON serialization/deserialization:
```ruby
require 'emery'

the_json = Jsoner.to_json(T.array(DateTime), [DateTime.new(2019, 11, 30, 17, 45, 55)])
# the_json is '["2019-11-30T17:45:55"]'

data = Jsoner.from_json(T.array(DateTime), '["2019-11-30T17:45:55+00:00"]')
# data is Array with the only one item which is corresponding DateTime
```