require 'spec_helper'
require 'metricks/compared_point'

describe Metricks::ComparedPoint do
  subject(:point_a) { Metricks::Point.new(time: Time.utc(2019, 9, 2, 14), sum: 15, count: 4, last: 12) }
  subject(:point_b) { Metricks::Point.new(time: Time.utc(2019, 9, 1, 14), sum: 20, count: 2, last: 5) }
  subject(:point) { Metricks::ComparedPoint.new(point_a, point_b) }

  context '#sum' do
    it 'should return the sum' do
      expect(point.sum).to be_a Metricks::Comparison
      expect(point.sum.difference).to eq -5.0
      expect(point.sum.percentage_change).to eq -25.0
    end
  end

  context '#count' do
    it 'should return the count' do
      expect(point.count).to be_a Metricks::Comparison
      expect(point.count.difference).to eq 2
      expect(point.count.percentage_change).to eq 100.0
    end
  end

  context '#last' do
    it 'should return the last' do
      expect(point.last).to be_a Metricks::Comparison
      expect(point.last.difference).to eq 7
      expect(point.last.percentage_change).to eq 140.0
    end
  end
end
