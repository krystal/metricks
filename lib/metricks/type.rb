require 'metricks/models/metric'

module Metricks
  class Type
    class << self
      def id(id = nil)
        id ? @id = id : @id
      end

      def association(slot, name, options = {})
        @associations ||= {}
        @associations[name] = options.merge(slot: slot)
      end

      def associations
        @associations ||= {}
      end

      # Transform a given amount into a different value when returning from
      # the database. Note that this is not used for serialization. All values
      # recorded will be stored as floats.
      #
      # @param amount [Float]
      # @param associations [Hash]
      # @return [Object]
      def transform_amount(amount, _associations)
        amount
      end

      # Resolve association integers into a map containing their "real" values
      # for this type
      #
      # @param assoc_name [Symbol]
      # @param integers [Array<Integer]
      # @raise [Metrics::Error]
      # @return [Hash]
      def resolve_association_integers(assoc_name, integers)
        assoc = associations[assoc_name]
        if assoc.nil?
          raise Metricks::Error.new('InvalidAssociationForResolution', "The association #{assoc_name} is not valid for #{self}")
        end

        if map = assoc[:map]
          map.invert
        elsif assoc[:model]
          # If the association defines a model, we can try and resolve these using that
          scope = @association[:model].constantize.where(id: integers)
          scope.each_with_object({}) do |obj, hash|
            hash[obj.id] = obj
          end
        else
          {}
        end
      end

      # Serialize a given association to a value that can be stored in an
      # association column
      #
      # @param assoc_name [Symbol]
      # @param value [Object]
      # @return [Integer, nil]
      def serialize_association_value(assoc_name, value)
        return nil if value.blank?

        assoc = associations[assoc_name]
        if map = assoc[:map]
          map[value]
        elsif assoc[:model]
          value.is_a?(ActiveRecord::Base) ? value.id : value.to_i
        else
          value.to_i
        end
      end

      # Executed when any metric for this type is recorded. Can modify the
      # metric as it sees fit and/or raise errors.
      #
      # @param metric [Metricks::Models::Metric]
      # @param options [Hash] the options provided to the `record` method
      # @raise [Metricks::Error]
      # @return [void]
      def before_record(_metric, _options)
        nil
      end

      # Executed after a metric has been recorded (not in the same transaction).
      #
      # @param metric [Metricks::Models::Metric]
      # @param options [Hash] the options provided to the `record` method
      # @return [void]
      def after_record(_metric, _options)
        nil
      end

      # Copy associations for this type onto the given metric based on the
      # given set of associations.
      #
      # @param metric [Metricks::Models::Metric]
      # @param given_associations [Hash]
      # @return [void]
      def copy_associations(metric, given_associations)
        return if associations.blank?

        associations.each do |assoc_name, assoc_details|
          if given_associations && association = given_associations[assoc_name.to_sym]
            association_value = serialize_association_value(assoc_name, association)
            metric.public_send("association_#{assoc_details[:slot]}=", association_value)
          elsif assoc_details[:required]
            raise Metricks::Error.new('MissingAssociation', message: "The :#{assoc_name} association was not provided but is required")
          end
        end

        true
      end

      # Returns a new scope containing appropriate where conditions for the
      # given associations
      #
      # @param scope [ActiveRecord::Relation]
      # @param given_associations [Hash]
      # @return [ActiveRecord::Relation]
      def add_associations_to_scope(scope, given_associations)
        return scope if associations.blank?

        given_associations ||= {}

        associations.each do |assoc_name, assoc_details|
          next if !given_associations.key?(assoc_name.to_sym) && !cumulative?

          value = serialize_association_value(assoc_name, given_associations[assoc_name.to_sym])
          scope = scope.where("association_#{assoc_details[:slot]}" => value)
        end

        scope
      end

      def record(**options)
        Models::Metric.record(self, **options)
      end

      def latest(**options)
        Models::Metric.latest(self, **options)
      end

      def gather(group, **options)
        Models::Metric.gather(self, group, **options)
      end

      def compare(group, **options)
        Models::Metric.compare(self, group, **options)
      end
    end
  end
end
