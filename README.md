# Experiments

This library allows you to define experiments


## Installation

Add this line to your application's Gemfile, and run `bundle install`:

    gem 'experiments'

## Usage

This gem contains the `Experiments::Experiment` model used create the experiment instance,
in order consistently modify application behaviour based on an object's unique key. 

Define an experiment like so:

``` ruby
Experiments::Experiment.define :my_experiment do

  # This block should return true if the subject is qualified to participate
  qualify { |subject, context|  ... }

  # Specify the groups and the percentages
  groups do
    group :test, :half
    group :control, :rest
  end

  # Specify how assignments will be stored.
  storage Experiments::Storage::Memory.new
end
```

Usually you want to place this in a file called **my_experiment.rb** in the 
**/app/experiments** folder.

Refer to the experiment elsewhere in your codebase like this:

``` ruby
context = { ... } # anything you want to pass along to the qualify block. 
case Experiments['my experiment'].switch(shop, context)
when :test
  # Handle test group
when :control
  # Handle control group
else 
  # Handle unqualified people. 
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes, including tests (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request, and mention @wvanbergen.
