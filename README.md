# Metricks 🎃

Metricks is an ActiveRecord-powered backend for storing historical numeric metrics within your application (things like MRR, active users, quantity of widgets sold, refunds given etc...).

The library provides the tools to define multiple types of metrics, record them in the database as well as providing tools to aggregate the results and run comparisons on different time periods.

## Installation

To get started, add the following to your Gemfile and run `bundle install`.

```ruby
source 'https://rubygems.pkg.github.com/adamcooke' do
  gem 'metricks', '>= 1.0.0', '< 2.0'
end
```

Once the gem is installed, you can copy the migrations into your application and run them:

```
rake metricks:install:migrations
rake db:migrate
```

## Usage

There are two key types of metric: evented or cumulative. By default, all metrics stored are evented which means they represent an event happening (for example an invoice being raised, a user being created or a product being sold). A cumulative metric stores values that increase or decrease (for example total revenue, MRR or number of active users).

Each type of metric you wish to store is represented by a class which inherits from either `Metricks::Types::Evented` or `Metricks::Types::Cumulative`. You can put these anywhere in your application that takes your fancy. Personally, I quite like `app/models/metrics/*` the choice is yours - putting all metrics in their own `Metrics` namespace is a good idea for readability later.

### Recording metrics

Metrics are all stored in the `metrics` table. It is expected this table may get large over time but has been optimised with appropriate indexes and the size is kept to a minimum. To help keep the table size down it does not contain any strings.

**The type of each metric is represented by a 32-bit integer in the database.** When you define your metric types you will need to specify an ID. This ID must be unique for this type of metric across your whole application.

#### Evented metrics

An event metric should inherit from `Metricks::Types::Evented` and at its most basic form will look like the below.

```ruby
class Metrics::PotatoesPicked < Metricks::Types::Evented
  id 10
end
```

Once you have defined your type, you can start storing metrics for it. For evented metrics, the default behaviour is to simply store `1` as the metric but you can choose any amount. If you're storing a counter, you'll want to keep this as `1` but if you're storing something like the value of invoices raised, you may want to store the total value of the invoice.

```ruby
# At the most basic, you can just record a single increment happening at the
# current time with the value of one.
Metrics::PotatoesPicked.record

# You can change the amount if you wish
Metrics::PotatoesPicked.record(amount: 201.50)

# You can also change the time that the metric should be recorded at
Metrics::PotatoesPicked.record(time: 2.months.ago)

# There are additional options for storing associations with metrics
# and you can find information about these further down this document.
```

#### Cumulative metrics

Cumulative metrics allow you to increment (or decrement) amount by a specified amount. This allows you to keep track of a metric that changes over time. For example, if you wanted to see how many users were active on a given date or what your currently MRR was at that point.

```ruby
class Metrics::TotalUsers < Metricks::Types::Cumulative
  id 20
end
```

The procedure for adding cumulative metrics is exactly the same as evented ones. By default, it will increment by 1 but you can change this by using a different value for `:amount` when calling `.record`. You can use negative numbers in the amount field to decrement the value.

While you can specify a time for a cumulative value, you will receive an error if you try to insert a historical event when you already have current data. This protects the integrity of the counter.

### Associations

If you wish to associate your metric with other parts of your application (for example you want to keep track of revenue in specific currencies or the number of widgets sold in different countries) you can do this using associations.

At heart, associations are very simple. They are simply an additional integer that is used when storing your metrics. There are 5 available slots for associations which can be defined for your metric. The most likely thing you'll want to associate with is another Active Record model.

```ruby
class Metrics::SalesByCountry < Metricks::Types::Cumulative
  id 40
  association 1, :country, required: true, model: 'Country'
end
```

Once you have added an association to a type, you can pass it when recording metrics. Metricks will handle serializing your model when recording and deserializing when it comes back out again.

```ruby
country = Country.find_by_name('Sweden')
Metrics::SalesByCountry.record(associations: {country: country})
```

You can also serialize the values from a hash usinng the `map` option.

```ruby
class Metrics::SalesByCurrency < Metricks::Types::Cumulative

  CURRENCIES = {usd: 1, gbp: 2, eur: 3}

  id 45
  association 1, :currency, required: true, map: CURRENCIES
end

set = Metrics::SalesByCurrency.gather(:hour, associations: {currency: :eur})
set = Metrics::SalesByCurrency.gather(:hour, associations: {currency: :gbp})
```

### Getting data

The primary method for obtaining metrics is the `.gather` method on your metric types. This will return a `Metricks::Set` instance which contains your data grouped by whatever time period you select. For each unit of the time period (i.e. each day, month, hour etc...) you'll be able to see a total of the amounts you've recorded, the number of metrics recorded and the last value for that unit.

There are 5 time groups you can choose from:

- `:hour` - group by each hour of the day
- `:day` - group by each day
- `:week` - group by each whole week of the year
- `:month` - group by each month
- `:year` - group by the year

When choosing which time period to return, you will specify an `end_time` and a `quantity`.

When passing a time (default is `Time.current`) it will be rounded to the end of the current period (based on the `group`) - for example, if you provide 4.30pm on 31st October 2019 and you're grouping by day, this will be rounded to `2019-10-31 23:59:59`.

The quantity is used to determine how many "time units" you want to return. The default for quantity varies depending on the group. For example, by default, when grouping by day you'll get 30 days worth of data but when grouping by hour you'll only get 24 hours (and 12 months, 3 years and 6 weeks).

```ruby
# The most basic form just specifies the time period
set = Metrics::PotatoesPicked.gather(:day)

# If you wish to change the time period you can (in this example)
# you'll get 10 days of data from 1 month ago working forwards).
set = Metrics::PotatoesPicked.gather(:day, end_time: 1.month.ago, quantity: 10)

# If you wish to only get data for a certain association, you
# can pass these.
set = Metrics::PotatoesPicked.gather(:day, association: {field: 2})

# If you also wish to group by an association, this is possible as well.
# In this case, you'll receive a hash with one item for each unique
# associated value
hash = Metrics::PotatoesPicked.gather(:day, group_by: :field)

# Obviously, all of these things can be combined together if needed.
```

#### Looking at `Metricks::Set`

The result for gathering is quite simple really and easily described in Ruby...

```ruby
set = Metrics::PotatoesPicked.gather(:day, time: Time.utc(2019, 10, 30))

# Initially you'll have information about the query that was
# actually executed for you.
set.type          # => Metrics::PotatoesPicked
set.group         # => :day
set.quantity      # => 30
set.start_time    # => Time[2019-10-01 00:00:00]
set.end_time      # => Time[2019-10-30 23:59:59]
set.associations  # => {}

# The raw data is also availble.
set.points        # => [Metricks::Point, Metricks::Point, ...]
```

One of the most useful operations on a set is the `.filled` method. This will return an array of points for each "unit" in the group even if there was no data in the database. These "filled" points will be zero (0.0) although the `last` option will be last value from the preceeding point.

#### Looking at points

For each point that comes out of the set you'll have a few options.

```ruby
point = set.points.first

point.sum   # => The sum of all items in the "unit"
point.count # => The number of metrics recorded
point.last  # => The last value recorded in this "unit"
```

### Comparisons

The comparison options allow you to compare multiple sets at the same time. The easiest way to generate a comparison is to use the `.compare` method. By default, this allows you to compare each point with the same point from the time period preceeding the one you've obtained.

```ruby
compared_set = Metrics::PotatoesPicked.compare(:month, end_time: Time.utc(2019, 12))

compared_set.a      # => The Metricks::Set for 2019-01 to 2019-12
compared_set.b      # => The Metricks::Set for 2018-01 to 2018-12
compared_set.points #=> [Metricks::ComparedPoint, Metricks::ComparedPoint, ...]

compared_set.points.first   # => A point containing data for 2019-01-01 and 2018-01-01
compared_set.points.last    # => A point containing data for 2019-12-01 and 2018-12-01
```

Unlike normal sets, a compared set will always be filled to ensure that data from both periods can be matched.

Looking at the points from our compared set you'll see that they're instances of `Metricks::ComparedPoint`. They behave a bit like this:

```ruby
compared_point = compared_set.points.first

compared_point.sum                    # => Metricks::Comparison
compared_point.sum.a                  # => The value from 2019-01-01
compared_point.sum.b                  # => The value from 2018-01-01
compared_point.sum.difference         # => The difference bween 2019-01 and 2018-01
compared_point.sum.percentage_change  # => The % change between 2019-01 and 2018-01

# In addition to `sum`, there is also `count` and `last` as you expect from any
# other point.
```
