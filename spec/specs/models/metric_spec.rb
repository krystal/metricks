require 'spec_helper'
require 'metricks/models/metric'

describe Metricks::Models::Metric do
  context 'a valid un-saved metric' do
    subject(:metric) do
      Metricks::Models::Metric.new(type: PotatoesPicked.id, amount: 10.0)
    end

    it 'should copy the time parts into appropriate columns' do
      metric.time = Time.utc(2019, 10, 22, 12, 22)
      expect(metric.save).to be true
      expect(metric.year).to eq 2019
      expect(metric.month).to eq 10
      expect(metric.day).to eq 22
      expect(metric.hour).to eq 12
      expect(metric.week_of_year).to eq 43
    end

    it 'should use the current time if no time is provided' do
      fake_time = Time.utc(2019, 6, 2, 17, 30)
      expect(Time).to receive(:current).and_return(fake_time)
      subject.time = nil
      expect(subject.save).to be true
      expect(subject.time).to eq fake_time
    end

    it 'should allow historical events to be inserted for evented metrics' do
      Metricks::Models::Metric.record(PotatoesPicked, time: Time.current)
      metric.time = 2.weeks.ago
      expect(metric.valid?).to be true
    end
  end

  context '.record' do
    it 'should create a new metric with 1 as the default amount' do
      metric = Metricks::Models::Metric.record(PotatoesPicked)
      expect(metric).to be_a Metricks::Models::Metric
      expect(metric.amount).to eq 1.0
    end

    it 'should raise an error if the type is not an instance of Metricks::Type' do
      expect do
        Metricks::Models::Metric.record(String)
      end.to raise_error(Metricks::Error) do |e|
        expect(e.code).to eq 'InvalidMetricType'
      end
    end

    it 'should raise an error for types without an ID' do
      expect do
        Metricks::Models::Metric.record(MetricWithoutID)
      end.to raise_error(Metricks::Error) do |e|
        expect(e.code).to eq 'MetricTypeMissingID'
      end

    end

    it 'should allow you to set an amount' do
      metric = Metricks::Models::Metric.record(PotatoesPicked, amount: 15.0)
      expect(metric).to be_a Metricks::Models::Metric
      expect(metric.amount).to eq 15.0
    end

    it 'should allow a time to be provided' do
      time = Time.utc(2019, 6, 2, 12, 20)
      metric = Metricks::Models::Metric.record(PotatoesPicked, time: time)
      expect(metric).to be_a Metricks::Models::Metric
      expect(metric.time).to eq time
    end

    it 'should increment from the previous if the type is cumulative' do
      Metricks::Models::Metric.record(TotalPotatoes, amount: 15.0)
      metric = Metricks::Models::Metric.record(TotalPotatoes, amount: 2)
      expect(metric.save).to be true
      expect(metric.amount).to eq 17
    end

    it 'should increment in the same association scope' do
      # No associations
      metric = Metricks::Models::Metric.record(TotalPotatoesSold)
      expect(metric.amount).to eq 1
      metric = Metricks::Models::Metric.record(TotalPotatoesSold)
      expect(metric.amount).to eq 2

      # Some permutation of associations
      metric = Metricks::Models::Metric.record(TotalPotatoesSold, associations: { currency: 1, field: 12 })
      expect(metric.amount).to eq 1
      metric = Metricks::Models::Metric.record(TotalPotatoesSold, associations: { currency: 1, field: 12 })
      expect(metric.amount).to eq 2
      metric = Metricks::Models::Metric.record(TotalPotatoesSold, associations: { currency: 1, field: 12 })
      expect(metric.amount).to eq 3

      # Another permutation of associations
      metric = Metricks::Models::Metric.record(TotalPotatoesSold, associations: { currency: 2, field: 33 })
      expect(metric.amount).to eq 1
      metric = Metricks::Models::Metric.record(TotalPotatoesSold, associations: { currency: 2, field: 33 })
      expect(metric.amount).to eq 2

      # Assumes package will be nil
      metric = Metricks::Models::Metric.record(TotalPotatoesSold, associations: { currency: 2 })
      expect(metric.amount).to eq 1
      metric = Metricks::Models::Metric.record(TotalPotatoesSold, associations: { currency: 2 })
      expect(metric.amount).to eq 2
    end

    it 'should not increment from the previous if the type if event' do
      Metricks::Models::Metric.record(PotatoesPicked, amount: 10.0)
      metric = Metricks::Models::Metric.record(PotatoesPicked)
      expect(metric.save).to be true
      expect(metric.amount).to eq 1
    end

    it 'should raise an error if a required association is missing' do
      expect do
        Metricks::Models::Metric.record(PotatoesPickedWithRequiredField)
      end.to raise_error(Metricks::Error) do |e|
        expect(e.code).to eq 'MissingAssociation'
      end
    end
  end

  context '.latest' do
    it 'should return 0.0 if there are no metrics' do
      value = Metricks::Models::Metric.latest(TotalPotatoes)
      expect(value).to eq 0.0
    end

    it 'should return the latest metric in scope' do
      Metricks::Models::Metric.record(TotalPotatoes, amount: 221)
      value = Metricks::Models::Metric.latest(TotalPotatoes)
      expect(value).to eq 221.0
    end

    it 'should transform point values' do
      PotatoesPickedAsInteger.record(amount: 10.5)
      value = Metricks::Models::Metric.latest(PotatoesPickedAsInteger)
      expect(value).to be_a Integer
      expect(value).to eq 10
    end

    it 'should return the latest metric before a given timestamp' do
      Metricks::Models::Metric.record(TotalPotatoes, amount: 140, time: Time.utc(2018, 6, 2, 12))
      Metricks::Models::Metric.record(TotalPotatoes, amount: 500, time: Time.utc(2019, 6, 2, 12))
      value = Metricks::Models::Metric.latest(TotalPotatoes, before: Time.utc(2019, 2, 2))
      expect(value).to eq 140
    end

    it 'should return the latest metric for the given associations' do
      Metricks::Models::Metric.record(TotalPotatoesSold, amount: 12, associations: { currency: 1 })
      value = Metricks::Models::Metric.latest(TotalPotatoesSold, associations: { currency: 1 })
      expect(value).to eq 12

      Metricks::Models::Metric.record(TotalPotatoesSold, amount: 44, associations: { currency: 2 })
      value = Metricks::Models::Metric.latest(TotalPotatoesSold, associations: { currency: 2 })
      expect(value).to eq 44
    end
  end

  context '.gather' do
    it 'should return a Metricks::Set' do
      set = Metricks::Models::Metric.gather(TotalPotatoes, :hour)
      expect(set).to be_a Metricks::Set
    end

    it 'should return the type' do
      set = Metricks::Models::Metric.gather(TotalPotatoes, :hour)
      expect(set.type).to eq TotalPotatoes
    end

    it 'should return the points' do
      set = Metricks::Models::Metric.gather(TotalPotatoes, :hour)
      expect(set.points).to be_a Array
      expect(set.points).to be_empty
    end

    it 'should transform point values' do
      PotatoesPickedAsInteger.record(amount: 10.5)
      set = Metricks::Models::Metric.gather(PotatoesPickedAsInteger, :hour)
      expect(set.points.first.sum).to be_a Integer
      expect(set.points.first.sum).to eq 10
    end

    context 'group by hour' do
      it 'should return 24 hours by default' do
        set = Metricks::Models::Metric.gather(TotalPotatoes, :hour)
        expect(set.quantity).to eq 24
      end

      it 'should return the group' do
        set = Metricks::Models::Metric.gather(TotalPotatoes, :hour)
        expect(set.group).to eq :hour
      end

      it 'should start at the beginning of the hour 24 hours ago' do
        expect(Time).to receive(:current).and_return(Time.utc(2019, 10, 20, 16, 23))
        set = Metricks::Models::Metric.gather(TotalPotatoes, :hour)
        expect(set.start_time).to eq Time.utc(2019, 10, 19, 17)
      end

      it 'should end at the end of an hour' do
        expect(Time).to receive(:current).and_return(Time.utc(2019, 10, 20, 16, 23))
        set = Metricks::Models::Metric.gather(TotalPotatoes, :hour)
        expect(set.end_time).to eq Time.utc(2019, 10, 20, 16, 59, 59).end_of_minute
      end

      it 'should return metrics grouped by hour' do
        time = Time.utc(2019, 10, 19, 16, 23)
        PotatoesPicked.record(time: time - 6.hours, amount: 10)
        PotatoesPicked.record(time: time - 2.hours, amount: 15)
        PotatoesPicked.record(time: time - 1.hour, amount: 20)
        PotatoesPicked.record(time: time, amount: 10)
        PotatoesPicked.record(time: time, amount: 10)

        set = PotatoesPicked.gather(:hour, end_time: time)
        expect(set.points.size).to eq 4
        expect(set.points).to all be_a Metricks::Point

        expect(set.points[0].time).to eq Time.utc(2019, 10, 19, 10)
        expect(set.points[0].sum).to eq 10.0
        expect(set.points[0].count).to eq 1

        expect(set.points[1].time).to eq Time.utc(2019, 10, 19, 14)
        expect(set.points[1].sum).to eq 15.0
        expect(set.points[1].count).to eq 1

        expect(set.points[2].time).to eq Time.utc(2019, 10, 19, 15)
        expect(set.points[2].sum).to eq 20.0
        expect(set.points[2].count).to eq 1

        expect(set.points[3].time).to eq Time.utc(2019, 10, 19, 16)
        expect(set.points[3].sum).to eq 20.0
        expect(set.points[3].count).to eq 2
      end

      it 'should fill with each hour in the day' do
        set = TotalPotatoes.gather(:hour, end_time: Time.utc(2019, 10, 19, 16, 23))
        filled = set.filled
        expect(filled.size).to eq 24
        expect(filled.first.time).to eq Time.utc(2019, 10, 18, 17)
        expect(filled[1].time).to eq Time.utc(2019, 10, 18, 18)
        expect(filled[2].time).to eq Time.utc(2019, 10, 18, 19)
        expect(filled[3].time).to eq Time.utc(2019, 10, 18, 20)
        expect(filled.last.time).to eq Time.utc(2019, 10, 19, 16)
      end
    end

    context 'group by day' do
      it 'should return 30 days by default' do
        set = Metricks::Models::Metric.gather(TotalPotatoes, :day)
        expect(set.quantity).to eq 30
      end

      it 'should return the group' do
        set = Metricks::Models::Metric.gather(TotalPotatoes, :day)
        expect(set.group).to eq :day
      end

      it 'should start at the beginning of the day 30 days ago' do
        expect(Time).to receive(:current).and_return(Time.utc(2019, 9, 30, 16, 23))
        set = Metricks::Models::Metric.gather(TotalPotatoes, :day)
        expect(set.start_time).to eq Time.utc(2019, 9, 1)
      end

      it 'should end at the end of the day today' do
        expect(Time).to receive(:current).and_return(Time.utc(2019, 9, 30, 16, 23))
        set = Metricks::Models::Metric.gather(TotalPotatoes, :day)
        expect(set.end_time).to eq Time.utc(2019, 9, 30, 23, 59, 59).end_of_minute
      end

      it 'should return metrics grouped by day' do
        time = Time.utc(2019, 10, 19, 16, 23)

        PotatoesPicked.record(time: time, amount: 10)
        PotatoesPicked.record(time: time, amount: 10)
        PotatoesPicked.record(time: time - 1.day, amount: 20)
        PotatoesPicked.record(time: time - 2.days, amount: 15)
        PotatoesPicked.record(time: time - 6.days, amount: 10)
        PotatoesPicked.record(time: time - 40.days, amount: 10)

        set = Metricks::Models::Metric.gather(PotatoesPicked, :day, end_time: time)
        expect(set.points.size).to eq 4
        expect(set.points).to all be_a Metricks::Point

        expect(set.points[0].time).to eq Time.utc(2019, 10, 13)
        expect(set.points[0].sum).to eq 10.0
        expect(set.points[0].count).to eq 1

        expect(set.points[1].time).to eq Time.utc(2019, 10, 17)
        expect(set.points[1].sum).to eq 15.0
        expect(set.points[1].count).to eq 1

        expect(set.points[2].time).to eq Time.utc(2019, 10, 18)
        expect(set.points[2].sum).to eq 20.0
        expect(set.points[2].count).to eq 1

        expect(set.points[3].time).to eq Time.utc(2019, 10, 19)
        expect(set.points[3].sum).to eq 20.0
        expect(set.points[3].count).to eq 2
      end

      it 'should fill with each day in the period' do
        set = Metricks::Models::Metric.gather(PotatoesPicked, :day, end_time: Time.utc(2019, 10, 19, 16, 23))
        filled = set.filled
        expect(filled.size).to eq 30
        expect(filled.first.time).to eq Time.utc(2019, 9, 20)
        expect(filled[1].time).to eq Time.utc(2019, 9, 21)
        expect(filled[2].time).to eq Time.utc(2019, 9, 22)
        expect(filled[3].time).to eq Time.utc(2019, 9, 23)
        expect(filled.last.time).to eq Time.utc(2019, 10, 19)
      end
    end

    context 'group by week' do
      it 'should return 6 weeks by default' do
        set = Metricks::Models::Metric.gather(PotatoesPicked, :week)
        expect(set.quantity).to eq 6
      end

      it 'should return the group' do
        set = Metricks::Models::Metric.gather(PotatoesPicked, :week)
        expect(set.group).to eq :week
      end

      it 'should start at the beginning of the week 6 weeks ago' do
        expect(Time).to receive(:current).and_return(Time.utc(2019, 10, 24, 10, 33))
        set = Metricks::Models::Metric.gather(PotatoesPicked, :week)
        expect(set.start_time).to eq Time.utc(2019, 9, 16)
      end

      it 'should end at the end of this week' do
        expect(Time).to receive(:current).and_return(Time.utc(2019, 10, 24, 10, 33))
        set = Metricks::Models::Metric.gather(PotatoesPicked, :week)
        expect(set.end_time).to eq Time.utc(2019, 10, 27, 23, 59, 59).end_of_minute
      end

      it 'should return metrics grouped by week' do
        time = Time.utc(2019, 10, 19, 16, 23)

        PotatoesPicked.record(time: time, amount: 10)
        PotatoesPicked.record(time: time, amount: 10)
        PotatoesPicked.record(time: time - 1.week, amount: 20)
        PotatoesPicked.record(time: time - 2.weeks, amount: 15)
        PotatoesPicked.record(time: time - 5.weeks, amount: 10)

        set = Metricks::Models::Metric.gather(PotatoesPicked, :week, end_time: time)
        expect(set.points.size).to eq 4
        expect(set.points).to all be_a Metricks::Point

        expect(set.points[0].time).to eq Time.utc(2019, 9, 9)
        expect(set.points[0].sum).to eq 10.0
        expect(set.points[0].count).to eq 1

        expect(set.points[1].time).to eq Time.utc(2019, 9, 30)
        expect(set.points[1].sum).to eq 15.0
        expect(set.points[1].count).to eq 1

        expect(set.points[2].time).to eq Time.utc(2019, 10, 7)
        expect(set.points[2].sum).to eq 20.0
        expect(set.points[2].count).to eq 1

        expect(set.points[3].time).to eq Time.utc(2019, 10, 14)
        expect(set.points[3].sum).to eq 20.0
        expect(set.points[3].count).to eq 2
      end

      it 'should fill with each week in the period' do
        set = Metricks::Models::Metric.gather(PotatoesPicked, :week, end_time: Time.utc(2019, 10, 19, 16, 23))
        filled = set.filled
        expect(filled.size).to eq 6
        expect(filled.first.time).to eq Time.utc(2019, 9, 9)
        expect(filled[1].time).to eq Time.utc(2019, 9, 16)
        expect(filled[2].time).to eq Time.utc(2019, 9, 23)
        expect(filled[3].time).to eq Time.utc(2019, 9, 30)
        expect(filled.last.time).to eq Time.utc(2019, 10, 14)
      end
    end

    context 'group by month' do
      it 'should return 12 months by default' do
        set = Metricks::Models::Metric.gather(PotatoesPicked, :month)
        expect(set.quantity).to eq 12
      end

      it 'should return the group' do
        set = Metricks::Models::Metric.gather(PotatoesPicked, :month)
        expect(set.group).to eq :month
      end

      it 'should start at the beginning of the month 12 months ago' do
        expect(Time).to receive(:current).and_return(Time.utc(2019, 10, 24, 10, 33))
        set = Metricks::Models::Metric.gather(PotatoesPicked, :month)
        expect(set.start_time).to eq Time.utc(2018, 11, 1)
      end

      it 'should end at the end of this month' do
        expect(Time).to receive(:current).and_return(Time.utc(2019, 10, 24, 10, 33))
        set = Metricks::Models::Metric.gather(PotatoesPicked, :month)
        expect(set.end_time).to eq Time.utc(2019, 10, 31, 23, 59, 59).end_of_minute
      end

      it 'should return metrics grouped by month' do
        time = Time.utc(2019, 10, 19, 16, 23)

        PotatoesPicked.record(time: time, amount: 10)
        PotatoesPicked.record(time: time, amount: 10)
        PotatoesPicked.record(time: time - 1.month, amount: 20)
        PotatoesPicked.record(time: time - 2.months, amount: 15)
        PotatoesPicked.record(time: time - 6.months, amount: 10)
        PotatoesPicked.record(time: time - 40.months, amount: 10)

        set = Metricks::Models::Metric.gather(PotatoesPicked, :month, end_time: time)
        expect(set.points.size).to eq 4
        expect(set.points).to all be_a Metricks::Point

        expect(set.points[0].time).to eq Time.utc(2019, 4, 1)
        expect(set.points[0].sum).to eq 10.0
        expect(set.points[0].count).to eq 1

        expect(set.points[1].time).to eq Time.utc(2019, 8, 1)
        expect(set.points[1].sum).to eq 15.0
        expect(set.points[1].count).to eq 1

        expect(set.points[2].time).to eq Time.utc(2019, 9, 1)
        expect(set.points[2].sum).to eq 20.0
        expect(set.points[2].count).to eq 1

        expect(set.points[3].time).to eq Time.utc(2019, 10, 1)
        expect(set.points[3].sum).to eq 20.0
        expect(set.points[3].count).to eq 2
      end

      it 'should fill with each month in the period' do
        set = Metricks::Models::Metric.gather(PotatoesPicked, :month, end_time: Time.utc(2019, 10, 19, 16, 23))
        filled = set.filled
        expect(filled.size).to eq 12
        expect(filled.first.time).to eq Time.utc(2018, 11)
        expect(filled[1].time).to eq Time.utc(2018, 12)
        expect(filled[2].time).to eq Time.utc(2019, 1)
        expect(filled[3].time).to eq Time.utc(2019, 2)
        expect(filled.last.time).to eq Time.utc(2019, 10)
      end
    end

    context 'group by year' do
      it 'should return 3 years by default' do
        set = Metricks::Models::Metric.gather(PotatoesPicked, :year)
        expect(set.quantity).to eq 3
      end

      it 'should return the group' do
        set = Metricks::Models::Metric.gather(PotatoesPicked, :year)
        expect(set.group).to eq :year
      end

      it 'should start at the beginning of the year 3 years ago' do
        expect(Time).to receive(:current).and_return(Time.utc(2019, 10, 24, 10, 33))
        set = Metricks::Models::Metric.gather(PotatoesPicked, :year)
        expect(set.start_time).to eq Time.utc(2017, 1, 1)
      end

      it 'should end at the end of this year' do
        expect(Time).to receive(:current).and_return(Time.utc(2019, 10, 24, 10, 33))
        set = Metricks::Models::Metric.gather(PotatoesPicked, :year)
        expect(set.end_time).to eq Time.utc(2019, 12, 31, 23, 59, 59).end_of_minute
      end

      it 'should return metrics grouped by month' do
        time = Time.utc(2019, 10, 19, 16, 23)

        PotatoesPicked.record(time: time, amount: 10)
        PotatoesPicked.record(time: time, amount: 10)
        PotatoesPicked.record(time: time - 1.year, amount: 20)
        PotatoesPicked.record(time: time - 2.years, amount: 15)
        PotatoesPicked.record(time: time - 6.years, amount: 10)

        set = Metricks::Models::Metric.gather(PotatoesPicked, :year, end_time: time)
        expect(set.points.size).to eq 3
        expect(set.points).to all be_a Metricks::Point

        expect(set.points[0].time).to eq Time.utc(2017)
        expect(set.points[0].sum).to eq 15.0
        expect(set.points[0].count).to eq 1

        expect(set.points[1].time).to eq Time.utc(2018)
        expect(set.points[1].sum).to eq 20.0
        expect(set.points[1].count).to eq 1

        expect(set.points[2].time).to eq Time.utc(2019)
        expect(set.points[2].sum).to eq 20.0
        expect(set.points[2].count).to eq 2
      end

      it 'should fill with each month in the period' do
        set = Metricks::Models::Metric.gather(PotatoesPicked, :year, end_time: Time.utc(2019, 10, 19, 16, 23))
        filled = set.filled
        expect(filled.size).to eq 3
        expect(filled.first.time).to eq Time.utc(2017)
        expect(filled[1].time).to eq Time.utc(2018)
        expect(filled[2].time).to eq Time.utc(2019)
      end
    end

    context 'group by associations' do
      it 'should ' do
        time = Time.utc(2019, 5, 10, 12)

        SpoiledPotatos.record(time: time - 1.day, amount: 10, associations: {field: 1})
        SpoiledPotatos.record(time: time - 2.day, amount: 20, associations: {field: 1})
        SpoiledPotatos.record(time: time - 6.day, amount: 60, associations: {field: 2})
        SpoiledPotatos.record(time: time - 3.day, amount: 30, associations: {field: 2})
        SpoiledPotatos.record(time: time - 3.day, amount: 40, associations: {field: 2})
        SpoiledPotatos.record(time: time - 5.day, amount: 50, associations: {field: 2})


        group = Metricks::Models::Metric.gather(SpoiledPotatos, :day, group_by: :field, end_time: time)
        expect(group).to be_a Hash
        expect(group.size).to eq 2
        expect(group.keys).to include 1
        expect(group.keys).to include 2
        expect(group[1]).to be_a Metricks::Set
        expect(group[1].points.size).to eq 2
        expect(group[2]).to be_a Metricks::Set
        expect(group[2].points.size).to eq 3
      end
    end
  end

  context '.compare' do

    it 'should return a compared set' do
      set = Metricks::Models::Metric.compare(PotatoesPicked, :hour)
      expect(set).to be_a Metricks::ComparedSet
    end

    it 'should include both sets' do
      set = Metricks::Models::Metric.compare(PotatoesPicked, :hour)
      expect(set.a).to be_a Metricks::Set
      expect(set.b).to be_a Metricks::Set
      expect(set.points).to be_a Array
      expect(set.points).to all be_a Metricks::ComparedPoint
      expect(set.points.size).to eq 24
    end

    it 'should provide comparisons' do
      PotatoesPicked.record(time: Time.utc(2019, 8, 19, 14), amount: 35.0)
      PotatoesPicked.record(time: Time.utc(2019, 8, 19, 13), amount: 50.0)
      PotatoesPicked.record(time: Time.utc(2019, 8, 18, 14), amount: 15.0)

      set = Metricks::Models::Metric.compare(PotatoesPicked, :hour, end_time: Time.utc(2019, 8, 19, 14))
      expect(set.a.points.size).to eq 2
      expect(set.b.points.size).to eq 1
      expect(set.points.size).to eq 24
      expect(set.points).to all be_a Metricks::ComparedPoint
      expect(set.points.last.sum.a).to eq 35.0
      expect(set.points.last.sum.b).to eq 15.0
      expect(set.points.last.sum.difference).to eq 20.0
      expect(set.points.last.sum.percentage_change.round(2)).to eq 133.33
    end
  end
end
