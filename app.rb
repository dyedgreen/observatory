require "scorched"

require "./classes/db.rb"
require "./classes/url.rb"

require "./views/base.rb"
require "./views/auth.rb"
require "./views/refer.rb"
require "./views/url.rb"


class App < Views::Base

  get "/" do
    # Url.create("https://tilman.xyz/understanding-cvaes").public_id
    (Url.new "https://tilman.xyz").public_id
    # render "index.html".to_sym
  end

  get "/test" do
    request.user_agent
  end

  get "/dashboard" do
    flash[:message]
  end

  controller "/static/", Views::Static
  controller "/r/", Views::Refer

  controller "/url", Views::Url

  # Make "/dashboard/" a controller

  controller "/", Views::Root # Provides special paths
  Views::Root << { pattern: "/", target: Views::User} # Provides login and account management

  after status: (300..600) do
    response.body = render "error.html.erb".to_sym
  end

end # App
