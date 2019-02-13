require "scorched"
require "rqrcode"
require "rotp"
require "base64"

require "./classes/user.rb"
require "./views/base.rb"

module Views

  class Protected < Base

    SESSION_TIMEOUT = 60 * 15 # in seconds

    middleware << proc {
      use Rack::Session::Cookie, secret: ENV["session_secret"]
    }

    def user?
      unless session["time"] && session["time"] < Time.new.to_i - SESSION_TIMEOUT
        session["time"] = Time.new.to_i
        return session["user"] ? session["user"] : nil
      end
      nil
    end

    def login(user)
      raise ArgumentError, "Uses does not exist" unless ::User.exist? user
      session["user"] = user.downcase
      session["time"] = Time.new.to_i
    end

    def logout
      session["user"] = nil
    end

  end # Protected

  class User < Protected

    before do
      unless user? || request.path[/login|register/]
        redirect "/login"
      end
      if !user? && request.path["register"] && ::User.count > 0
        redirect "/login"
      end
      if user? && request.path["login"]
        redirect "/account"
      end
    end

    get "/account" do
      render_register ::User.make_secret, nil, "account.html.erb"
    end

    post "/account" do
      secret = request.POST["secret"]
      code_old = request.POST["code_old"]
      code_new = request.POST["code_new"]
      error = nil

      if secret.length != 32
        error = "Something went wrong, please reload the page."
      elsif !::User.valid? code_new, secret
        error = "The new code is invalid."
      elsif !::User.exist? user?
        error = "User does not exist."
      elsif !::User.new(user?).valid? code_old
        error = "The old code is invalid."
      end

      unless error
        ::User.new(user?).update_secret secret
        redirect "/"
      end

      render_register secret, error, "account.html.erb"
    end

    get "/login" do
      render "login.html.erb".to_sym, locals: {:error => nil}
    end

    post "/login" do
      username = request.POST["username"]
      error = nil
      if !::User.exist? username
        error = "User does not exist."
      elsif !::User.new(username).valid? request.POST["code"]
        error = "Invalid code."
      end

      unless error
        login username
        redirect "/"
      end
      render "login.html.erb".to_sym, locals: {:error => error}
    end

    get "/logout" do
      logout
      redirect "/login"
    end

    get "/register" do
      render_register ::User.make_secret, nil
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

      render_register secret, error
    end

    def render_register(secret, error, template="register.html.erb")
      render template.to_sym, locals: {
        :error => error ? error : nil,
        :qr_secret => qr_code(secret),
        :secret => secret,
      }
    end

    def qr_code(secret)
      url = ROTP::TOTP.new(secret).provisioning_uri("")
      "data:image/svg+xml;base64,#{Base64.encode64(RQRCode::QRCode.new(url).as_svg)}"
    end

  end # User

end
