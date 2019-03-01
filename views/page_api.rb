require "scorched"

require "./views/api.rb"


module Views

  class Test < Api
    get_json "/" do
      (0..5).to_a
    end

    post_json "/pesto" do
      false
    end

    get_json "/fail" do
      # halt 500
      raise AppError.new "This is very wrong..."
    end
  end

end
