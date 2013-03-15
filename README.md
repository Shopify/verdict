# Experiments

The Experiment functionality has been extracted from Shoppify so that it can be used to do A/B tests on other applications

## Installation

Add this line to your application's Gemfile:

    gem 'experiments'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install experiments

## Usage

This gem contains the Experiment and ShopExperiment model used create the experiment singleton and modify application behaviour. Define the experiment like so:

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

See the vault article for more details:

[https://vault.shopify.com/creating-an-experiment-in-shopify](https://vault.shopify.com/creating-an-experiment-in-shopify)
