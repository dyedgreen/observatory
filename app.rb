require "scorched"

require "./classes/db.rb"

require "./views/base.rb"
require "./views/auth.rb"


class App < Views::Base

  get "/" do
    render "index.html".to_sym
  end

  controller "/user", Views::User
  controller "/static", Views::Static

  after status: 404 do
    response.body = render "404.html".to_sym
  end

end
