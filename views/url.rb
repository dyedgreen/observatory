require "scorched"

require "./classes/url.rb"
require "./views/auth.rb"

module Views

  class Url < Protected

    symbol_matchers[:public_id] = [/\A[a-zA-Z0-9]{8}\Z/, proc { |v| v }]

    get "/" do
      page = request.GET["page"] || 0
      render "url_list.html.erb".to_sym
    end

    get "/:public_id" do
      halt 404 unless ::Url.exist? captures[:public_id]
      url = ::Url.new captures[:public_id]
      url.target
    end

    get "/:public_id/hits" do
      halt 404 unless ::Url.exist? captures[:public_id]
      url = ::Url.new captures[:public_id]

      page = request.GET["page"] || 0
      page

      (url.hits.map { |v| v.created }).join "<br>"
    end

  end # Refer

end
