# Experiments

This library allows you to define and use experiments in your application.

- This library can be used in any Ruby application, and comes with a `Railtie` to
  make integrating it with a Rails app easy.
- This library only handles consistently assigning subjects to experiment groups, 
  and storing/logging these assignments for analysis. It doesn't do any analysis
  of results. That should happen elsewhere, e.g. in a data warehouse environment.


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
  storage Experiments::Storage::MemoryStorage.new
end
```

Usually you want to place this in a file called **my_experiment.rb** in the 
**/app/experiments** folder. Also, usually you want to subclass `Experiments::Experiment` 
to set some default options for your app's environment, and call `define` on that class
instead.

Refer to the experiment elsewhere in your codebase like this:

``` ruby
context = { ... } # anything you want to pass along to the qualify block. 
case Experiments['my experiment'].switch(shop, context)
when :test
  # Handle test group
when :control
  # Handle control group
else 
  # Handle unqualified subjects. 
end
```

## Storage & logging

The library uses a basic interface to store experiment assignments. Except for
a development-only memory store, it doesn't include any storage models.

You can set up storage by calling the `storage` method of your experiment, with
an object that responds to the following tho methods:

- `def retrieve_assignment(experiment, subject_identifier)`
- `def store_assignment(assignment)`

In which `experiment` is the Experiment instance, `subject_identifier` is a  
string that uniquely identifies the subject, and `assignment` is an
`Experiment::Assignment` instance. By default it will use `subject.id.to_s` as
`subject_identifier`, but you can change that by overriding the 
`def subject_identifier(subject)` method on the experiment.

The library will also log every assignment to `Experiments.logger`. The Railtie
sets `Experiment.logger` to `Rails.logger`, so experiment assignments will show
up in your Rails log. You can override the logging by overriding the 
`def log_assignment(assignment)` method on the experiment.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes, including tests (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request, and mention @wvanbergen.
