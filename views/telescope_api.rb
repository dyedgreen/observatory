require "scorched"

require "./classes/track.rb"
require "./views/api.rb"


module Views

  class VisitApi < Api
    post_json "/record" do
      site = Track::Site.new request.POST["host"]
      if request.POST["referrer"] != ""
        site.record_event({"ref" => request.POST["referrer"]})
      else
        site.record_event
      end
    end
  end

  class ViewApi < Api
    post_json "/record" do
      site = Track::Site.new request.POST["host"]
      site.create_page(request.POST["path"]) unless site.page_exist? request.POST["path"]
      site.record_page_view(request.POST["path"])
    end
  end

end
