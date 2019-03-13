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

    get "/*/delete" do |site_id|
      halt 404 unless Track::Site.exist? site_id.to_i
      render(
        "partials/confirm_delete.html".to_sym,
        locals: { title: "Delete Url" },
        layout: "layouts/form.html.erb".to_sym
      )
    end

    post "/*/delete" do |site_id|
      halt 404 unless Track::Site.exist? site_id.to_i
      site = Track::Site.new site_id.to_i
      site.delete
      flash[:message] = "Deleted host '#{site.host}'."
      redirect "/settings"
    end
  end # Settings

end
