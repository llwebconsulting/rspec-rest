# frozen_string_literal: true

module RSpec
  module Rest
    module Deprecation
      module_function

      def warn(key:, message:)
        return if already_emitted?(key)

        emit("DEPRECATION: #{message}")
      end

      def reset!
        emitted_keys.clear
      end

      def already_emitted?(key)
        normalized_key = key.to_s
        return true if emitted_keys[normalized_key]

        emitted_keys[normalized_key] = true
        false
      end
      private_class_method :already_emitted?

      def emitted_keys
        @emitted_keys ||= {}
      end
      private_class_method :emitted_keys

      def emit(message)
        reporter = rspec_reporter
        if reporter.respond_to?(:message)
          reporter.message(message)
        else
          Kernel.warn(message)
        end
      end
      private_class_method :emit

      def rspec_reporter
        return nil unless defined?(::RSpec) && ::RSpec.respond_to?(:configuration)

        ::RSpec.configuration.reporter
      rescue StandardError
        nil
      end
      private_class_method :rspec_reporter
    end
  end
end
