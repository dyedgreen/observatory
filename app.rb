require "scorched"

require "./classes/auth.rb"
require "./classes/db.rb"
require "./classes/view.rb"


class App < Scorched::Controller

  render_defaults[:dir] = "./web"

  get "/" do
    render "index.html".to_sym
  end

  controller "/user", UserController
  controller "/css", StyleController

  after status: 404 do
    response.body = render "404.html".to_sym
  end

end
