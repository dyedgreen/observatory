require "scorched"


module Views

  CONTENT_TYPE = Hash.new("text/plain").merge!({
    "png"   => "image/png",
    "jpg"   => "image/jpeg",
    "jpeg"  => "image/jpeg",
    "gif"   => "image/gif",
    "svg"   => "image/svg+xml",
    "ttf"   => "font/ttf",
    "woff"  => "font/woff",
    "woff2" => "font/woff2",
    "eot"   => "application/vnd.ms-fontobject",
    "html"  => "text/html",
    "css"   => "text/css",
    "js"    => "text/javascript",
  })

  class Base < Scorched::Controller

    render_defaults[:dir] = "./web"
    render_defaults[:locals] = {}

    def locals(locals)
      render_defaults[:locals].merge locals
    end

  end # Base

  class Static < Base

    # Serve scss style sheets
    get "/styles/*.css" do |file|
      response["Content-Type"] = "text/css"
      render file_path("styles/#{file}.scss").to_sym, engine: :scss
    end

    # Serve typescript scripts
    get "/scripts/*.js" do |file|
      response["Content-Type"] = "text/javascript"
      render file_path("scripts/#{file}.ts").to_sym, engine: :ts
    end

    # Serve any other static files
    get "/**" do |file|
      file_path "static/#{file}"
      response["Content-Type"] = CONTENT_TYPE[file.split(".")[-1]]
      File.open("#{render_defaults[:dir]}/static/#{file}").read
    end

    def file_path(path)
      path = path[1,] if path[0] == "/"
      unless File.exist? "#{render_defaults[:dir]}/#{path}"
        halt 404
      end
      path
    end

  end # Static

end
