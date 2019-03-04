require "scorched"

require "./classes/track.rb"
require "./views/base.rb"


module Views

  class Refer < Base
    symbol_matchers[:public_id] = [/[a-zA-Z0-9]{8}(\-[a-zA-Z]+)*/, proc { |v| v.split("-").first.to_s }]

    get "/:public_id" do
      halt 404 unless Track::Url.exist? captures[:public_id]
      url = Track::Url.new captures[:public_id]
      meta = {}.merge! request.GET
      if meta.key?("utm_source") && !meta.key?("ref")
        meta["ref"] = meta["utm_source"]
      end
      meta.merge!({ "user_agent" => request.user_agent })
      url.record_event meta
      redirect url.target_with_protocol
    end
  end # Refer

end
