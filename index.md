---
layout: index
---

# Verdict

[![Build Status](https://travis-ci.org/Shopify/verdict.png)](https://travis-ci.org/Shopify/verdict)
[![Code Climate](https://codeclimate.com/github/Shopify/verdict.png)](https://codeclimate.com/github/Shopify/verdict)

This library allows you to define and use experiments in your application.

- It can be used in any Ruby application, and comes with a `Railtie` to make integrating it with a Rails app easy.
- It handles consistently assigning subjects to experiment groups, and storing/logging these assignments for analysis.

__*This library doesn't do any analysis of results. That should happen elsewhere, e.g. in a data warehouse environment.*__


## Installation

Add this line to your application's Gemfile, and run `bundle install`:

    gem 'verdict'

If you're using Rails, the Railtie will handle setting the logger to `Rails.logger` and the experiments directory to `app/experiments`. It will also load the rake tasks for you (run `bundle exec rake -T | grep experiments:` for options).

## Usage

The `Verdict::Experiment` class is used to create an experiment, define control and experiment groups, and to qualify subjects.

You define an experiment like so:

``` ruby
Verdict::Experiment.define :my_experiment do

  # This block should return true if the subject is qualified to participate
  qualify { |subject, context|  ... }

  # Specify the groups and the percentages
  groups do
    group :test, :half
    group :control, :rest
  end

  # Specify how assignments will be stored.
  storage Verdict::Storage::MemoryStorage.new
end
```

Usually you'll want to place this in a file called **my_experiment.rb** in the
**/app/experiments** folder.

_We recommend that you subclass `Verdict::Experiment` to set some default options for your app's environment, and call `define` on that class instead._

### Determining a Subject's Group

At the relevant point in your application, you can check the group that a particular subject belongs to using the `switch` method.

You'll need to pass along the subject (think User, Product or any other Model class) as well as any context to be used for qualifying the subject.

``` ruby
context = { ... } # anything you want to pass along to the qualify block.
case Verdict['my experiment'].switch(shop, context)
when :test
  # Handle test group
when :control
  # Handle control group
else
  # Handle unqualified subjects.
end
```

## Storage

Verdict uses a very simple interface for storing experiment assignments. Out of the box, Verdict ships with storage providers for:

* Memory
* Redis

You can set up storage for your experiment by calling the `storage` method with
an object that responds to the following methods:

* `store_assignment(assignment)`
* `retrieve_assignment(experiment, subject_identifier)`
* `remove_assignment(experiment, subject_identifier)`
* `retrieve_start_timestamp(experiment)`
* `store_start_timestamp(experiment, timestamp)`

Regarding the method signatures above, `experiment` is the Experiment instance, `subject_identifier` is a string that uniquely identifies the subject, and `assignment` is a `Verdict::Assignment` instance.

By default it will use `subject.id.to_s` as `subject_identifier`, but you can change that by overriding `def subject_identifier(subject)` on the experiment.

Storage providers simply store subject assignments and require quick lookups of subject identifiers. They allow for complex (high CPU) assignments, and for assignments that might not always put the same subject in the same group by storing the assignment for later use.

Storage providers are intended for operational use and should not be used for data analysis. For data analysis, you should use the logger.

For more details about these methods, check out the source code for [Verdict::Storage::MockStorage](lib/verdict/storage/mock_storage.rb)

## Logging

Every assignment will be logged to `Verdict.logger`. For rails apps, this logger will be automatically set to `Rails.logger` so experiment assignments will show up in your Rails log.

You can override the logging by overriding the `def log_assignment(assignment)` method on the experiment.

Logging (as opposed to storage) should be used for data analysis. The logger requires a write-only / forward-only stream to write to, e.g. a log file, Kafka, or an insert-only database table.

It's possible to run an experiment without defining any storage, though this comes with several drawbacks. Logging on the other hand is required in order to analyze the results.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes, including tests (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request, and mention @wvanbergen.
