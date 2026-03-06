# frozen_string_literal: true

module RSpec
  module Rest
    module JsonTypeHelpers
      def integer
        be_a(Integer)
      end

      def string
        be_a(String)
      end

      def boolean
        satisfy("be boolean") { |value| [true, false].include?(value) }
      end

      def array_of(matcher)
        all(matcher)
      end

      def hash_including(*)
        a_hash_including(*)
      end
    end
  end
end
