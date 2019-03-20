require "scorched"
require "json"

require "./classes/error.rb"
require "./views/base.rb"
require "./views/auth.rb"


module Views

  class Api < Auth
    after do
      response["Content-Type"] = "application/json"
      response["Cache-Control"] = "no-cache"
      # Allow cross origin requests
      response["Access-Control-Allow-Headers"] = "*"
      response["Access-Control-Allow-Origin"] = "*"
    end

    after status: (401..600) do
      response.body = { error: STATUS_STR[response.status], data: nil }.to_json
    end

    def wrap(*vals, &block)
      begin
        response = instance_exec(*vals, &block)
        { error: nil, data: response }.to_json
      rescue AppError => err
        halt 400, { error: err.to_s, data: nil }.to_json
      end
    end

    def self.get_json(*args, **nargs, &block)
      get(*args, **nargs) do |*vals|
        wrap(*vals, &block)
      end
    end

    def self.post_json(*args, **nargs, &block)
      post(*args, **nargs) do |*vals|
        wrap(*vals, &block)
      end
    end
  end # Api

  class ProtectedApi < Api
    before do
      # TODO: Think about how to authenticate
      #       users... Cookie? Token in request?
    end
  end # ProtectedApi

end
