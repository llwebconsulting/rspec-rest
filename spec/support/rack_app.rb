# frozen_string_literal: true

class RackApp
  def call(env)
    users = [
      { "id" => 1, "email" => "jane@example.com", "name" => "Jane" },
      { "id" => 2, "email" => "alex@example.com", "name" => "Alex" }
    ]
    next_id = 3

    req = Rack::Request.new(env)

    if req.get? && req.path == "/v1/users"
      return json_response(200, users)
    end

    if req.post? && req.path == "/v1/users"
      payload = parse_body(req.body.read)
      user = {
        "id" => next_id,
        "email" => payload["email"] || "unknown@example.com",
        "name" => payload["name"] || "Unknown"
      }
      users << user
      return json_response(201, user)
    end

    if req.get? && req.path.match(%r{\A/v1/users/(\d+)\z})
      user_id = Regexp.last_match(1).to_i
      user = users.find { |u| u["id"] == user_id }
      return json_response(200, user) if user

      return json_response(404, { "error" => "not found" })
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
end
