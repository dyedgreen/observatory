require "scorched"

require "./classes/url.rb"
require "./views/auth.rb"

module Views

  class Url < Protected

    symbol_matchers[:public_id] = [/[a-zA-Z0-9]{8}/, proc { |v| v }]

    get "/" do
      render(
        "url_list.html.erb".to_sym,
        locals: { :title => "Urls", :page => (request.GET["page"] || 0).to_i },
        layout: "layouts/page.html.erb".to_sym
      )
    end

    post "/create" do
      begin
        url = ::Url.create request.POST["target"]
        flash[:message] = "Created url '#{url.target}'."
        redirect "/url/#{url.public_id}"
      rescue AppError => e
        render(
          "url_create.html.erb".to_sym,
          locals: { :title => "Create Url", :error => e.to_s },
          layout: "layouts/form.html.erb".to_sym
        )
      end
    end

    get "/:public_id" do
      halt 404 unless ::Url.exist? captures[:public_id]
      url = ::Url.new captures[:public_id]
      render(
        url.target,
        locals: { :title => url.target[/([^\/.]+\.)?[^\/.]+\.[^\/.]{3,}/][/[^.]+\.[^.]+\Z/] },
        layout: "layouts/page.html.erb".to_sym
      )
    end

    get "/:public_id/delete" do
      halt 404 unless ::Url.exist? captures[:public_id]
      render(
        "partials/confirm_delete.html".to_sym,
        locals: { :title => "Delete Url" },
        layout: "layouts/form.html.erb".to_sym
      )
    end

    post "/:public_id/delete" do
      begin
        halt 404 unless ::Url.exist? captures[:public_id]
        url = ::Url.new captures[:public_id]
        url.delete
        flash[:message] = "Deleted url '#{url.target}'"
        redirect "/url"
      rescue AppError => e
        render(
          "partials/confirm_delete.html".to_sym,
          locals: { :title => "Delete Url", :error => e.to_s },
          layout: "layouts/form.html.erb".to_sym
        )
      end
    end

    get "/:public_id/hits" do
      halt 404 unless ::Url.exist? captures[:public_id]
      url = ::Url.new captures[:public_id]

      page = request.GET["page"] || 0
      page

      (url.hits.map { |v| v.created }).join "<br>"
    end

    def public_target(url)
      "#{request.host_with_port.sub /:80(?!\d)/, ''}/r/#{url.public_id}"
    end

  end # Refer

end
