require 'metricks/models/metric'
require 'metricks/point'

module Metricks
  class Set
    attr_reader :type
    attr_reader :group
    attr_reader :associations
    attr_reader :start_time
    attr_reader :end_time
    attr_reader :points
    attr_reader :quantity

    def initialize(type:, group:, associations:, start_time:, end_time:, points:, quantity:)
      @type = type
      @group = group
      @associations = associations
      @start_time = start_time
      @end_time = end_time
      @points = points
      @quantity = quantity
    end

    # Return all known points grouped by their time
    #
    # @return [Hash<Time, Metric::Point>]
    def points_by_time
      @points_by_time ||= begin
        @points.each_with_object({}) do |point, hash|
          hash[point.time] = point
        end
      end
    end

    # Return an array of points with any periods which have no data filled with
    # appropriate data.
    #
    # @return [Array<Metric::Point>]
    def filled
      @filled ||= begin
        previous = nil
        @quantity.times.map do |i|
          time = @start_time + i.public_send(@group)
          point = points_by_time[time]

          if point.nil?
            proposed_values = { count: 0 }
            proposed_values[:sum] = @type.transform_amount(0.0, @associations)
            proposed_values[:last] = @type.transform_amount(0.0, @associations)

            if i.zero?
              # We'll need to lookup the last previous value from the
              # database because we don't have it any longer.
              proposed_values[:last] = Models::Metric.latest(@type, associations: @associations, before: @start_time)
            else
              proposed_values[:last] = previous.last
            end

            point = Point.new(time: time, **proposed_values)
          end

          previous = point
          point
        end
      end
    end
  end
end
