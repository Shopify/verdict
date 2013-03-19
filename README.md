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

This gem contains the Experiment model used create the experiment singleton and consistently modify application behaviour based on an object's unique key. Define the experiment like so:

    AnnualVsMonthly = Experiment.new("annual vs monthly") do |ab|
      ab.percentage 10, :monthly
      ab.rest :yearly
    end
    
Modify app behaviour like so:

    case AnnualVsMonthly.group_for(shop)
    when :monthly
      # monthly stuff
    else
      # yearly stuff
    end

The real important bit is the hashing algorithm used to decide what group a shop or entity will belong to, without having to set cookies or do database inserts.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
