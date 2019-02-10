require "scorched"

require "./classes/db.rb"

require "./views/base.rb"
require "./views/auth.rb"


class App < Views::Protected

  get "/" do
    render "index.html".to_sym
  end

  controller "/user", Views::User
  controller "/static", Views::Static

  after status: 404 do
    response.body = render "error.html.erb".to_sym
  end

end
