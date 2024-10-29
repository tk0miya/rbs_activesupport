# rbs_activesupport

rbs_activesupport is a RBS generator for Active Support.

## Installation

Add a new entry to your Gemfile and run `bundle install`:

    group :development do
      gem 'rbs_activesupport', require: false
    end

After the installation, please run rake task generator:

    bundle exec rails g rbs_activesupport:install

And then, please modify `lib/tasks/rbs_activesupport.rake` to fit your application.
For example, set it up like this if you're using Rails configuration:

    RbsActivesupport::RakeTask.new do |task|
      task.target_directories = [Rails.root / "app", Rails.root / "lib"]
    end

## Usage

Run `rbs:activesupport:setup` task:

    bundle exec rake rbs:activesupport:setup

Then rbs_activesupport will scan your source code and generate RBS file into `sig/activesupport` directory.

rbs_activesupport will generate types for the following code:

* auto-extend on including ActiveSupport::Concern module
* delegate
* class_attribute, cattr_* and mattr_*


### auto-extend on including ActiveSupport::Concern module

The concern modules using `ActiveSupport::Concern` can provide the sub module named
`ClassMethods`.  It is useful to define class methods to the including class.

Extending the `ClassMethods` on including the concern module goes automatically and
silently.  So developers who uses the concern modules don't know the concern modules
automatically call "extend" in the background.

On the other hand, in the Type World, Steep and RBS does not support auto-extending.
Therefore we need to define the "extend" call manually.

For example, we need to write the "extend" call like the following:

```ruby
# user.rbs
class User
  include ActiveModel::Attribute
  extend ActiveModel::Attribute::ClassMethods
end
```

rbs_activesupport detects the including concern modules and generates the "extend"
call automatically if the concern modules have `ClassMethods` module.

### delegate

ActiveSupport provides `delegate` method to delegate the method calls to the other
objects.  It's very useful and powerful.

But RBS generators like `rbs prototype rb` and `rbs-inline` does not support it.
As a result, the delegation methods are missing in the RBS files.

rbs_activesupport detects the `delegate` method call and generates the types for
them automatically.

### class_attribute, cattr_* and mattr_*

ActiveSupport provides some methods to define class attributes and accessors:

* `class_attribute`
* `cattr_accessor`, `cattr_reader`, `cattr_writer`
* `mattr_accessor`, `mattr_reader`, `mattr_writer`

rbs_activesupport detects the calls of these methods and generates the types
for them.

Additionally, rbs_activesupport also supports the type annotation comment like RBS::Inline.

```ruby
class User
  class_attribute :name  #: String
end
```

rbs_activesupport also supports class attributes definition inside the "included" block:

```ruby
module MyConcern
  extend ActiveSupport::Concern

  included do
    class_attribute :name #: String
  end
end

class User
  include MyConcern
end
```

It is translated to the following RBS:

```ruby
module MyConcern
  extend ActiveSupport::Concern
end

class User
  include MyConcern

  def self.name: () -> String
  def self.name=: (String) -> String
  def self.name?: () -> bool
  def name: () -> String
  def name=: (String) -> String
  def name?: () -> bool
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also
run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

To release a new version, update the version number in `version.rb`, and then put
a git tag (ex. `git tag v1.0.0`) and push it to the GitHub. Then GitHub Actions
will release a new package to [rubygems.org](https://rubygems.org) automatically.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tk0miya/rbs_activesupport.
This project is intended to be a safe, welcoming space for collaboration, and contributors are
expected to adhere to the [code of conduct](https://github.com/tk0miya/rbs_activesupport/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the rbs_activesupport project's codebases, issue trackers is expected to
follow the [code of conduct](https://github.com/tk0miya/rbs_activesupport/blob/main/CODE_OF_CONDUCT.md).
