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

  controller "/static", Views::Static
  controller "/r", Views::Refer

  controller "/", Views::User

  after status: (300..600) do
    response.body = render "error.html.erb".to_sym
  end

end
