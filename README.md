# Experiments

The Experiment functionality has been extracted from Shopify so that it can be used to do A/B tests on other applications


## Installation

Add this line to your application's Gemfile:

    gem 'experiments'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install experiments


## Usage

This gem contains the `Experiments::Experiment` model used create the experiment singleton and consistently modify application behaviour based on an object's unique key. Define an experiment like so:

    Experiments.define 'my experiment' do

      qualify { |subject|  ... }

      groups do
        group :a, :half
        group :b, :rest
      end

      storage Experiments::Storage::Memory.new
    end

Refer to the experiment like this:

    case Experiments['my experiment'].assign(shop)
    when :half
      ...
    when :rest
      ...
    end


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes, including tests (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request, and mention @wvanbergen.
