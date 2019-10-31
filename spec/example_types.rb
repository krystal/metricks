require 'metricks/type'

class TotalPotatoes < Metricks::Types::Cumulative
  id 10
end

class PotatoesPicked < Metricks::Types::Evented
  id 20
end

class PotatoesPickedWithRequiredField < Metricks::Types::Evented
  id 21
  association 1, :field, required: true
end

class TotalPotatoesSold < Metricks::Types::Cumulative
  id 30
  association 1, :currency
  association 2, :field
end

class SpoiledPotatos < Metricks::Types::Evented
  id 40
  association 1, :field
end

class PotatoesPickedAsInteger < Metricks::Types::Evented
  id 50

  def self.transform_amount(amount, _associations = {})
    amount.to_i
  end
end

class MetricWithoutID < Metricks::Types::Evented
end
