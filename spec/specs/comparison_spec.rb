require 'spec_helper'
require 'metricks/compared_point'

describe Metricks::Comparison do
  context 'initialize' do
    it 'should accept a and b' do
      c = Metricks::Comparison.new(10, 20)
      expect(c.a).to eq 10
      expect(c.b).to eq 20
    end
  end

  context '#difference' do
    it 'should calculate the difference' do
      c = Metricks::Comparison.new(80, 20)
      expect(c.difference).to eq 60.0
    end
  end

  context '#percentage_change' do
    it 'should calculate a percentage' do
      c = Metricks::Comparison.new(100, 50)
      expect(c.percentage_change).to eq 100.0
    end

    it 'should return nil if the second value is zero' do
      c = Metricks::Comparison.new(100, 0)
      expect(c.percentage_change).to eq nil
    end

    it 'should return 0 if the difference is zero' do
      c = Metricks::Comparison.new(100, 100)
      expect(c.percentage_change).to eq 0
    end
  end
end
