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

  STATUS_STR = Hash.new("Something went wrong").merge!({
    204 => "No content",
    203 => "Non authoritative information",
    400 => "Bad request",
    403 => "Forbidden",
    404 => "Page not found",
    405 => "Method not allowed",
    500 => "Internal server error",
  })

  class Base < Scorched::Controller

    middleware << proc {
      use Rack::Session::Cookie, secret: ENV["SESSION_SECRET"]
    }

    render_defaults[:dir] = "./web"

    def status_string(status)
      STATUS_STR[status]
    end

    def escape_html(str)
      return str unless str.is_a? String
      str.gsub("<", "&lt;").gsub(">", "&gt;")
    end

    def format_time(time)
      time.to_s.sub " +0000", ""
    end

    def format_date(time)
      time.to_s[/\d+-\d+-\d+/]
    end

  end # Base

  class Static < Base

    config[:cache_templates] = true unless ENV["RACK_ENV"] == "development"

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

  class Root < Base

    get "/favicon.ico" do
      path = file_path "favicon.ico"
      response["Content-Type"] = "image/x-icon"
      File.open(path).read
    end

    get "/robots.txt" do
      path = file_path "robots.txt"
      response["Content-Type"] = "text/plain"
      File.open(path).read
    end

    get "/humans.txt" do
      path = file_path "humans.txt"
      response["Content-Type"] = "text/plain"
      File.open(path).read
    end

    def file_path(file)
      path = "#{render_defaults[:dir]}/static/#{file}"
      halt 404 unless File.exist? path
      path
    end

  end # Root

end
