require "scorched"

require "./classes/db.rb"
require "./classes/url.rb"

require "./views/base.rb"
require "./views/auth.rb"
require "./views/refer.rb"
require "./views/url.rb"


class App < Views::Auth

  get "/" do
    render "index.html.erb".to_sym
  end

  # get "/test" do
  #   now = Time.new.to_i
  #   day = 24 * 60 * 60
  #   [1,50,20,4,2,7,11,0,0,5,2,1].each_with_index do |val, idx|
  #     val.times do
  #       $db.execute <<-SQL, [17, Time.at(now - day*20 - day*idx).to_i]
  #         insert into url_hits (url, created) values (?, ?)
  #       SQL
  #     end
  #   end
  #   render "done!"
  # end

  controller "/static/", Views::Static
  controller "/r/", Views::Refer

  # controller "/dashboard", Views::Url
  controller "/url", Views::Url

  controller "/", Views::Root # Provides special paths
  Views::Root << { pattern: "/", target: Views::User } # Provides login and account management

  after status: (300..600), media_type: "text/html" do
    response.body = render "error.html.erb".to_sym
  end

end # App
