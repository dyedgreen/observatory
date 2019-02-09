require "scorched"


class StyleController < Scorched::Controller

  render_defaults[:dir] = "./web/styles"

  get "/*.css" do |file|
    file = "#{file}.scss"
    unless File.exist? render_defaults[:dir] + "/" + file
      halt 404
    end
    response["Content-Type"] = "text/css"
    render file.to_sym, engine: :scss
  end

end
