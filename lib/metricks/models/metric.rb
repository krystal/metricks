require 'with_advisory_lock'
require 'metricks/gatherer'
require 'metricks/error'
require 'metricks/compared_set'

module Metricks
  module Models
    class Metric < ActiveRecord::Base

      self.inheritance_column = 'sti_type'

      scope :before, -> (time) { where('time < ?', time) }
      scope :after, -> (time) { where('time > ?', time) }
      scope :newest_first, -> { order('id desc') }

      before_validation :set_time
      before_validation :set_time_parts

      class << self
        # Record a new metric
        #
        # @param type [Class]
        # @option options [Time] :time
        # @option options [Float] :amount
        # @return [Metric]
        def record(type, **options)
          unless type.ancestors.include?(Metricks::Type)
            raise Metricks::Error.new('InvalidMetricType', message: 'The metric type provided by must inherit from Metricks::Type')
          end

          unless type.id
            raise Metricks::Error.new('MetricTypeMissingID', message: "The metric type provided (#{type}) does not specify an ID")
          end

          metric = self.new
          metric.type = type.id
          metric.time = options[:time] || Time.current

          type.on_record(metric, options)
          type.copy_associations(metric, options[:associations])

          metric.amount ||= options[:amount] || 1

          if type.cumulative?
            with_advisory_lock 'AddCumulativeMetric' do
              existing = self.last(type, after: metric.time, associations: options[:associations])
              if existing.present?
                raise Metricks::Error.new('CannotAddHistoricalCumulativeMetrics', message: "Nope.")
              end

              previous = self.latest(type, associations: options[:associations])
              metric.amount = (previous + type.transform_amount(metric.amount, options[:associations])).to_f
              metric.save!
            end
          else
            metric.save!
          end

          metric
        end

        # Get the latest value recorded for a given scope
        #
        # @param type [Class]
        # @return [Float]
        def latest(type, **options)
          scope = self.last(type, **options)
          value = scope.pluck(:amount)&.first || 0.0
          type.transform_amount(value, options[:associations])
        end

        # Return the last metric for a given type
        #
        # @param type [Class]
        # @param before [Time]
        # @param after [Time]
        # @param associations [Hash]
        # @return [Metric]
        def last(type, before: nil, after: nil, associations: nil)
          scope = Metric.where(type: type.id).order(id: :desc)
          scope = scope.before(before) if before
          scope = scope.after(after) if after
          scope = type.add_associations_to_scope(scope, associations)
          scope
        end

        # Gather up metrics and return a set
        #
        # @param type [Class]
        # @param group [Symbol]
        # @return [Metricks::Set]
        def gather(type, group, **options)
          gatherer = Gatherer.new(type, group, **options)
          gatherer.gather
        end

        # Gather two sets of results and return a comparison
        #
        # @param type [Class]
        # @param group [Symbol]
        # @return [Metricks::ComparedSet]
        def compare(type, group, **options)
          a = self.gather(type, group, **options)
          b = self.gather(type, group, **options.merge(end_time: a.start_time - 1.public_send(group)))

          ComparedSet.new(a, b)
        end
      end

      private

      def set_time
        return if self.time

        self.time = Time.current
      end

      def set_time_parts
        utc = self.time

        self.year = utc.year
        self.month = utc.month
        self.day = utc.day
        self.hour = utc.hour
        self.week_of_year = utc.to_date.cweek
      end

    end
  end
end
