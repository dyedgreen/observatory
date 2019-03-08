require "scorched"

require "./classes/track.rb"
require "./views/auth.rb"


module Views

  class Settings < Protected
    get "/" do
      render(
        "settings.html.erb".to_sym,
        locals: { title: "Settings", sites: Track::Site.list },
        layout: "layouts/page.html.erb".to_sym
      )
    end

    get "/create" do
      render(
        "settings_create.html.erb".to_sym,
        locals: { title: "Add Host", error: nil },
        layout: "layouts/form.html.erb".to_sym
      )
    end

    post "/create" do
      begin
        site = Track::Site.create request.POST["host"]
        flash[:message] = "Created white-list entry for '#{site.host}'."
        redirect "/settings"
      rescue AppError => e
        render(
          "settings_create.html.erb".to_sym,
          locals: { title: "Add Host", error: e.to_s },
          layout: "layouts/form.html.erb".to_sym
        )
      end
    end
  end # Settings

end
