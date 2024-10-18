require 'with_advisory_lock' if defined?(WithAdvisoryLock)

# The default locking mechanism is to use the with_advisory_lock gem
# But this can be overriden using an initializer in the host Rails application (refer to README.md)
# This is set in lib/metricks/engine.rb
# Because of this, the with_advisory_lock gem is not a hard dependency.
module Metricks
  class Lock

    class << self
      attr_accessor :with_lock

      def with_lock(key, opts = {}, &block)
        with_lock_block = @with_lock || default_with_lock

        instance_exec(key, opts, block, &with_lock_block)
      end

      def validate!
        return if @with_lock.present?
        return if defined?(WithAdvisoryLock)


        raise Metricks::Error.new(
          'ConfigurationMissing',
          message: 'By default Metricks requires with_advisory_lock gem to be installed. ' \
          'Alternatively a custom locking mechanism can be configured via config.metricks.with_lock'
        )
      end

      private

      def default_with_lock
        proc do |key, opts, block|
          ActiveRecord::Base.with_advisory_lock(key, opts, &block)
        end
      end
    end
  end
end
