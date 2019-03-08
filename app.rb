require "scorched"

require "./classes/db.rb"

require "./views/base.rb"
require "./views/auth.rb"
require "./views/api.rb"
require "./views/refer.rb"
require "./views/url.rb"
require "./views/dashboard.rb"
require "./views/settings.rb"
require "./views/visit_api.rb"

class Api < Views::Api
  controller "/visit", Views::VisitApi
end

class App < Views::Auth
  get "/" do
    render "index.html.erb".to_sym
  end

  controller "/static/", Views::Static
  controller "/r/", Views::Refer

  controller "/api", Api

  controller "/dashboard", Views::Dashboard
  controller "/url", Views::Url
  controller "/settings", Views::Settings

  controller "/", Views::Root # Provides special paths
  Views::Root << { pattern: "/", target: Views::User } # Provides login and account management

  after status: (300..600), media_type: "text/html" do
    response.body = render "error.html.erb".to_sym unless request.path[/\A\/api/]
  end
end # App
