require "scorched"

require "./classes/track.rb"
require "./views/auth.rb"


module Views

  class Dashboard < Protected
    get "/" do
      sites = Track::Site.list
      if sites.count > 0
        render_dashboard sites.first
      else
        render_empty
      end
    end

    get "/*" do |site_id|
      if Track::Site.exist? site_id.to_i
        render_dashboard Track::Site.new site_id.to_i
      else
        render_empty
      end
    end

    def render_dashboard(site)
      render(
        "dashboard.html.erb".to_sym,
        locals: { title: "Dashboard", site: site },
        layout: "layouts/page.html.erb".to_sym
      )
    end

    def render_empty
      render(
        "partials/empty.html.erb".to_sym,
        locals: { title: "Dashboard" },
        layout: "layouts/page.html.erb".to_sym
      )
    end
  end # Dashboard

end
