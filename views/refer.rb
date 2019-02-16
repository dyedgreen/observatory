require "scorched"

require "./classes/url.rb"
require "./views/base.rb"

module Views

  class Refer < Base

    symbol_matchers[:public_id] = [/[a-zA-Z0-9]{8}(\-[a-zA-Z]+)*/, proc { |v| v.split("-").first.to_s }]

    get "/:public_id" do
      halt 404 unless ::Url.exist? captures[:public_id]
      url = ::Url.new captures[:public_id]
      meta = Hash.new.merge! request.GET
      meta.merge!({ "user_agent" => request.user_agent })
      url.hit meta
      redirect url.target
    end

  end # Refer

end
