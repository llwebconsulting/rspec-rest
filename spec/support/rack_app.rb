# frozen_string_literal: true

class RackApp
  def initialize
    @users = [
      { "id" => 1, "email" => "jane@example.com", "name" => "Jane" },
      { "id" => 2, "email" => "alex@example.com", "name" => "Alex" }
    ]
    @next_id = 3
  end

  def call(env)
    req = Rack::Request.new(env)

    if req.get? && req.path == "/v1/users"
      return json_response(200, @users)
    end

    if req.post? && req.path == "/v1/users"
      payload = parse_body(req.body.read)
      user = {
        "id" => @next_id,
        "email" => payload["email"] || "unknown@example.com",
        "name" => payload["name"] || "Unknown"
      }
      @users << user
      @next_id += 1
      return json_response(201, user)
    end

    if req.get? && req.path.match(%r{\A/v1/users/(\d+)\z})
      user_id = Regexp.last_match(1).to_i
      user = @users.find { |u| u["id"] == user_id }
      return json_response(200, user) if user

      return json_response(404, { "error" => "not found" })
    end

    if req.get? && req.path == "/v1/flags"
      return json_response(200, { "enabled" => true })
    end

    if req.get? && req.path == "/v1/posts"
      posts = [
        { "id" => 3, "title" => "Third" },
        { "id" => 2, "title" => "Second" },
        { "id" => 1, "title" => "First" }
      ]

      per_page = [integer_param(req, :per_page, default: posts.size), 20].min
      page = [integer_param(req, :page, default: 1), 1].max
      offset = (page - 1) * per_page
      return json_response(200, posts.slice(offset, per_page) || [])
    end

    if req.get? && req.path == "/v1/errors/string"
      return json_response(422, { "error" => "Unable to save post" })
    end

    if req.get? && req.path == "/v1/errors/array"
      return json_response(422, { "error" => ["Name can't be blank", "font_size is invalid"] })
    end

    if req.get? && req.path == "/v1/errors/list"
      return json_response(422, ["top-level array error"])
    end

    if req.post? && req.path == "/v1/uploads"
      upload = req.params["file"]
      return json_response(400, { "error" => "file is required" }) if upload.nil?

      unless req.media_type == "multipart/form-data"
        return json_response(400, { "error" => "request must be multipart/form-data" })
      end

      tempfile = upload[:tempfile] || upload["tempfile"]
      tempfile.rewind if tempfile.respond_to?(:rewind)
      size = tempfile.read.to_s.bytesize if tempfile.respond_to?(:read)
      tempfile.rewind if tempfile.respond_to?(:rewind)

      return json_response(
        201,
        {
          "filename" => upload[:filename] || upload["filename"],
          "content_type" => upload[:type] || upload["type"],
          "size" => size || 0
        }
      )
    end

    if req.get? && req.path == "/v1/bad_json"
      return [200, { "Content-Type" => "text/plain" }, ["this is not json"]]
    end

    json_response(404, { "error" => "route not found" })
  end

  private

  def json_response(status, payload)
    [status, { "Content-Type" => "application/json" }, [JSON.dump(payload)]]
  end

  def parse_body(body)
    return {} if body.nil? || body.empty?

    JSON.parse(body)
  rescue JSON::ParserError
    {}
  end

  def integer_param(req, key, default:)
    return default unless req.params.key?(key.to_s)

    Integer(req.params[key.to_s], 10)
  rescue ArgumentError, TypeError
    default
  end
end
