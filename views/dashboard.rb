require "scorched"

require "./classes/track.rb"
require "./views/auth.rb"


module Views

  class Dashboard < Protected
    get "/" do
      render(
        "todo",
        locals: { title: "Dashboard" },
        layout: "layouts/page.html.erb".to_sym
      )
    end
  end # Dashboard

end
