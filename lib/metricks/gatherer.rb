require 'metricks/error'
require 'metricks/point'
require 'metricks/set'
require 'metricks/models/metric'

module Metricks
  class Gatherer

    GROUPING = {
      hour: {
        group_by: [:year, :month, :day, :hour],
        quantity: 24,
        time_creator: proc { |m| Time.utc(m.year, m.month, m.day, m.hour) }
      },
      day: {
        group_by: [:year, :month, :day],
        quantity: 30,
        time_creator: proc { |m| Time.utc(m.year, m.month, m.day) }
      },
      month: {
        group_by: [:year, :month],
        quantity: 12,
        time_creator: proc { |m| Time.utc(m.year, m.month) }
      },
      year: {
        group_by: [:year],
        quantity: 3,
        time_creator: proc { |m| Time.utc(m.year) }
      },
      week: {
        group_by: [:year, :week_of_year],
        quantity: 6,
        time_creator: proc do |m|
          date = Date.commercial(m.year, m.week_of_year)
          Time.utc(date.year, date.month, date.day)
        end
      }
    }.freeze

    def initialize(type, group, quantity: nil, end_time: nil, associations: nil, group_by: nil)
      @type = type
      unless @type.ancestors.include?(Metricks::Type)
        raise Metricks::Error.new('InvalidTypeForGathering', message: 'The type must inherit from Metricks::Type')
      end

      @group = group
      unless GROUPING[@group.to_sym]
        raise Metricks::Error.new('InvalidGroupForGathering', message: "The group '#{group}' is not valid for gathering")
      end

      if group_by
        @association_name = group_by
        @association = @type.associations[@association_name]
        if @association.nil?
          raise Metricks::Error.new('InvalidAssociationForGathering', message: "The association #{association} is not valid for #{@type} metrics")
        end
      end

      @associations = associations
      @quantity = quantity
      @end_time = (end_time || Time.current).utc.public_send("end_of_#{@group}")
      @start_time = (@end_time - (self.quantity - 1).public_send(@group)).public_send("beginning_of_#{@group}")
    end

    def quantity
      @quantity || GROUPING[@group][:quantity] || 5
    end

    def raw_metrics
      @raw_metrics ||= begin
        scope = Models::Metric.where(type: @type.id)
        scope = scope.where(time: @start_time..@end_time)
        scope = @type.add_associations_to_scope(scope, @associations)
        scope = scope.select('SUM(amount) as sum, COUNT(*) as count, MAX(id) as last_id')
        scope = scope.select(*GROUPING[@group][:group_by])
        scope = scope.group(*GROUPING[@group][:group_by])

        if @association
          scope = scope.select("association_#{@association[:slot]} AS assoc")
          scope = scope.group('assoc')
        end

        scope
      end
    end

    def last_values
      @last_values ||= begin
        ids = raw_metrics.map(&:last_id)
        Models::Metric.where(id: ids).each_with_object({}) do |m, hash|
          hash[m.id] = m
        end
      end
    end

    def raw_metrics_as_points
      @raw_metrics_as_points ||= begin
        raw_metrics.each_with_object({}) do |metric, hash|
          if @association
            # We have some association so we'll group by the
            # assoc value on the metric.
            assoc_value = metric.assoc
          else
            # There's no associations here
            assoc_value = nil
          end

          last_value = self.last_values[metric.last_id]&.amount

          hash[assoc_value] ||= []
          hash[assoc_value] << Point.new(
            time: GROUPING[@group][:time_creator].call(metric),
            sum: @type.transform_amount(metric.sum.to_f, @associations),
            count: metric.count,
            last: last_value ? @type.transform_amount(last_value.to_f, @associations) : nil
          )
        end
      end
    end

    def gather
      if @association
        self.raw_metrics_as_points.each_with_object({}) do |(assoc, points), hash|
          resolved_assoc_object = resolved_association_keys[assoc] || assoc
          hash[resolved_assoc_object] = create_set_with_points(points)
        end
      else
        points = self.raw_metrics_as_points[nil] || []
        create_set_with_points(points)
      end
    end

    def resolved_association_keys
      return {} unless @association

      @resolved_association_keys ||= begin
        @type.resolve_association_integers(@association_name, raw_metrics_as_points.keys)
      end
    end

    private

    def create_set_with_points(points)
      Metricks::Set.new(
        type: @type,
        group: @group,
        associations: @associations,
        start_time: @start_time,
        end_time: @end_time,
        points: points,
        quantity: self.quantity
      )
    end

  end
end
