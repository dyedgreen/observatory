require "scorched"

require "./classes/track.rb"
require "./views/api.rb"


module Views

  class VisitApi < Api
    get_json "/" do
      (0..5).to_a
    end

    post_json "/create" do
      request.POST
    end

    get_json "/fail" do
      # halt 500
      raise AppError.new "This is very wrong..."
    end
  end

end
