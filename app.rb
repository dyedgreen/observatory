require "scorched"

require "./classes/db.rb"

require "./views/base.rb"
require "./views/auth.rb"
require "./views/refer.rb"
# require "./views/url.rb"


class App < Views::Auth

  get "/" do
    render "index.html.erb".to_sym
  end

  controller "/static/", Views::Static
  controller "/r/", Views::Refer

  # controller "/dashboard", Views::Url
  # controller "/url", Views::Url

  controller "/", Views::Root # Provides special paths
  Views::Root << { pattern: "/", target: Views::User } # Provides login and account management

  after status: (300..600), media_type: "text/html" do
    response.body = render "error.html.erb".to_sym
  end

end # App
