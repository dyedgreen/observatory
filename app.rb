require "scorched"

require "./classes/db.rb"

require "./views/base.rb"
require "./views/auth.rb"


class App < Views::Base

  get "/" do
    render "index.html".to_sym
  end

  controller "/static", Views::Static
  controller "/", Views::User

  after status: (300..600) do
    response.body = render "error.html.erb".to_sym
  end

end
