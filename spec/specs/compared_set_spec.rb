require 'spec_helper'
require 'metricks/compared_set'
require 'metricks/set'

describe Metricks::ComparedSet do
  subject(:currency) { create(:currency) }
  subject(:set_a) do
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
  subject(:set_b) do
    Metricks::Set.new(
      type: PotatoesPicked,
      group: :day,
      start_time: Time.utc(2019, 9, 1),
      end_time: Time.utc(2019, 9, 30),
      quantity: 30,
      associations: {},
      points: [
        Metricks::Point.new(time: Time.utc(2019, 9, 3), sum: 20.0, count: 2, last: 10.0),
        Metricks::Point.new(time: Time.utc(2019, 9, 6), sum: 100.0, count: 5, last: 25.0),
        Metricks::Point.new(time: Time.utc(2019, 9, 12), sum: 10.0, count: 1, last: 10.0)
      ]
    )
  end

  context '#initialize' do
    it 'should create an array of points with both sets' do
      cs = Metricks::ComparedSet.new(set_a, set_b)
      expect(cs.points).to be_a Array
      expect(cs.points.size).to eq 30
    end
  end
end
