require 'spec_helper'
require 'metricks/compared_set'
require 'metricks/set'

describe Metricks::Set do
  subject(:set) do
    Metricks::Set.new(
      type: PotatoesPicked,
      group: :day,
      start_time: Time.utc(2019, 10, 1),
      end_time: Time.utc(2019, 10, 30),
      quantity: 30,
      associations: {},
      points: [
        Metricks::Point.new(time: Time.utc(2019, 10, 2), sum: 20.0, count: 2, last: 10.0),
        Metricks::Point.new(time: Time.utc(2019, 10, 6), sum: 100.0, count: 5, last: 25.0),
        Metricks::Point.new(time: Time.utc(2019, 10, 12), sum: 10.0, count: 1, last: 10.0)
      ]
    )
  end

  context '#points_by_time' do
    it 'should return a hash' do
      expect(set.points_by_time).to be_a Hash
      expect(set.points_by_time.size).to eq 3
      expect(set.points_by_time[Time.utc(2019, 10, 2)]).to be_a Metricks::Point
      expect(set.points_by_time[Time.utc(2019, 10, 1)]).to be nil
    end
  end

  context '#filled' do
    it 'should return an array with points for each day' do
      filled = set.filled
      expect(filled).to be_a Array
      expect(filled.size).to eq 30
      expect(filled[0].time). to eq Time.utc(2019, 10, 1)
      expect(filled[0].sum).to eq 0

      expect(filled[1].time). to eq Time.utc(2019, 10, 2)
      expect(filled[1].sum).to eq 20.0

      expect(filled.last.time).to eq Time.utc(2019, 10, 30)
      expect(filled.last.sum).to eq 0.0
    end

    it 'should be able to fill the last value from the previous entry' do
      filled = set.filled
      expect(filled[1].last).to eq 10.0
      expect(filled[2].last).to eq 10.0
      expect(filled[3].last).to eq 10.0
      expect(filled[4].last).to eq 10.0
      expect(filled[5].last).to eq 25.0
    end

    it 'should be able to get last value from the database for the start' do
      PotatoesPicked.record(amount: 458, time: Time.utc(2019, 9, 30))
      filled = set.filled
      expect(filled[0].last).to eq 458.0
      expect(filled[1].last).to eq 10.0
    end
  end
end
