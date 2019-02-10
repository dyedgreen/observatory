require "scorched"
require "rqrcode"
require "rotp"
require "base64"

require "./classes/user.rb"
require "./views/base.rb"

module Views

  class Protected < Base

    middleware << proc {
      use Rack::Session::Cookie, secret: ENV["session_secret"]
    }

    def user?
      session["user"] ? session["user"] : nil
    end

    def login(user)
      session["user"] = user.downcase
    end

    def logout
      session["user"] = nil
    end

  end # Protected

  class User < Protected

    ROUTE = "/user"

    before do
      unless user? || request.path[/login|register/]
        redirect "#{ROUTE}/login"
      end
      if !user? && request.path["register"] && ::User.count > 0
        redirect "#{ROUTE}/login"
      end
    end

    get "/" do
      user?.inspect
    end

    get "/login" do
      # login "tilman"
      # redirect "/"
    end

    get "/logout" do
      logout
      redirect "#{ROUTE}/login"
    end

    get "/register" do
      render_register "", ::User.make_secret, nil
    end

    post "/register" do
      secret = request.POST["secret"]
      code = request.POST["code"]
      username = request.POST["username"].downcase
      error = nil

      if secret.length != 32
        error = "Something went wrong, please reload the page."
      elsif username[/\A[a-z0-9]{3,64}\Z/] != username
        error = "Please specify a valid username."
      elsif !::User.valid? code, secret
        error = "The code is invalid."
      elsif ::User.exist? username
        error = "This username is taken."
      end

      unless error
        ::User.new username, secret
        login username
        redirect "/"
      end

      render_register username, secret, error
    end

    def render_register(username, secret, error)
      render "register.html.erb".to_sym, locals: {
        :error => error ? error : nil,
        :qr_secret => qr_code(secret),
        :secret => secret,
        :username => username,
      }
    end

    def qr_code(secret)
      url = ROTP::TOTP.new(secret).provisioning_uri("")
      "data:image/svg+xml;base64,#{Base64.encode64(RQRCode::QRCode.new(url).as_svg)}"
    end

  end # User

end
