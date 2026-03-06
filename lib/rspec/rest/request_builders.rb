# frozen_string_literal: true

require "rack/test"

module RSpec
  module Rest
    module RequestBuilders
      def header(key, value)
        rest_request_state[:headers][key] = value
      end

      def headers(value)
        rest_request_state[:headers].merge!(value)
      end

      def query(value)
        rest_request_state[:query] ||= {}
        rest_request_state[:query].merge!(value)
      end

      def json(value)
        rest_request_state[:json] = value
      end

      def multipart!
        rest_request_state[:multipart] = true
        rest_request_state[:params] ||= {}
      end

      def file(param_key, file_or_path, content_type: nil, filename: nil)
        multipart!
        rest_request_state[:params][param_key] = build_uploaded_file(
          file_or_path,
          content_type: content_type,
          filename: filename
        )
      end

      def path_params(value)
        rest_request_state[:path_params].merge!(value.transform_keys(&:to_s))
      end

      def bearer(token)
        header("Authorization", "Bearer #{token}")
      end

      def unauthenticated!
        header("Authorization", nil)
      end

      private

      def build_uploaded_file(file_or_path, content_type:, filename:)
        return file_or_path if file_or_path.is_a?(Rack::Test::UploadedFile)

        path = if file_or_path.respond_to?(:to_path)
                 file_or_path.to_path
               else
                 file_or_path.to_s
               end

        Rack::Test::UploadedFile.new(path, content_type, false, original_filename: filename)
      end
    end
  end
end
