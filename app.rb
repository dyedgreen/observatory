require "scorched"

require "./classes/db.rb"
require "./classes/url.rb"

require "./views/base.rb"
require "./views/auth.rb"
require "./views/refer.rb"


class App < Views::Base

  get "/" do
    (Url.new "https://tilman.xyz").public_id
    # render "index.html".to_sym
  end

  get "/dashboard" do
    flash[:message]
  end

  controller "/static/", Views::Static
  controller "/r/", Views::Refer

  # Make "/dashboard/" a controller

  controller "/", Views::User

  after status: (300..600) do
    response.body = render "error.html.erb".to_sym
  end

end
