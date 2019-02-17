require "scorched"
require "rqrcode"
require "rotp"
require "base64"

require "./classes/user.rb"
require "./views/base.rb"

module Views

  class Auth < Base

    SESSION_TIMEOUT  = 60 * 15 # in seconds, time until inactive session terminates
    SESSION_DURATION = 24 * 60 * 60 # in seconds, time until a session fully expires

    def user?
      session["auth_user"] = nil unless (session["auth_start"] || 0) + SESSION_DURATION > Time.new.to_i
      session["auth_user"] = nil unless (session["auth_time"] || 0) + SESSION_TIMEOUT > Time.new.to_i
      session["auth_time"] = Time.new.to_i if session["auth_user"]
      session["auth_user"]
    end

    def login(username, code)
      user = ::User.new username
      user.login code
      session["auth_user"] = user.name
      session["auth_time"] = Time.new.to_i
      session["auth_start"] = Time.new.to_i
    end

    def fake_login
      # To create temporary fake users
      # on initial application load
      session["auth_user"] = ""
      session["auth_time"] = Time.new.to_i
      session["auth_start"] = Time.new.to_i
    end

    def logout
      session["auth_user"] = nil
    end

  end # Auth

  class Protected < Auth

    before do
      unless user?
        flash[:login_target] = request.path
        redirect "/login"
      end
    end

  end # Protected

  class User < Auth

    LOGGED_IN_PATH = "/dashboard" # Default login target

    before do
      if ["/account", "/register"].include?(request.path) && !user?
        flash[:login_target] = request.path
        redirect "/login"
      elsif request.path == "/login" && user?
        redirect LOGGED_IN_PATH
      end
    end

    get "/login" do
      render(
        "login.html.erb".to_sym,
        locals: { :title => "Login", :error => nil },
        layout: "layouts/form.html.erb".to_sym
      )
    end

    post "/login" do
      # First time login (no users in db)
      if ::User.count == 0
        fake_login
        flash[:message] = "Logged in with temporary user. Please register a new user immediately."
        redirect LOGGED_IN_PATH
      end
      # Normal login flow
      begin
        login request.POST["username"], request.POST["code"]
        redirect flash[:login_target] ? flash[:login_target] : LOGGED_IN_PATH
      rescue AppError => err
        render(
          "login.html.erb".to_sym,
          locals: { :title => "Login", :error => err.to_s },
          layout: "layouts/form.html.erb".to_sym
        )
      end
    end

    get "/logout" do
      logout
      redirect "/login"
    end

    get "/account" do
      render(
        "account.html.erb".to_sym,
        locals: { :title => "Account", :error => nil, :secret => ::User.make_secret },
        layout: "layouts/form.html.erb".to_sym
      )
    end

    post "/account" do
      begin
        user = ::User.new user?
        raise AppError.new("The old login code is not valid.") unless user.valid? request.POST["code_old"]
        user.update_secret request.POST["secret"], request.POST["code_new"]
        flash[:message] = "Updated secret for user #{user?}."
        redirect LOGGED_IN_PATH
      rescue AppError => err
        render(
          "account.html.erb".to_sym,
          locals: { :title => "Account", :error => err.to_s, :secret => request.POST["secret"]},
          layout: "layouts/form.html.erb".to_sym
        )
      end
    end

    get "/register" do
      render(
        "register.html.erb".to_sym,
        locals: { :title => "Register", :error => nil, :secret => ::User.make_secret },
        layout: "layouts/form.html.erb".to_sym
      )
    end

    post "/register" do
      begin
        ::User.create request.POST["username"], request.POST["secret"], request.POST["code"]
        flash[:message] = "Created user #{request.POST["username"]}."
        redirect LOGGED_IN_PATH
      rescue AppError => err
        render(
          "register.html.erb" .to_sym,
          locals: { :title => "Register", :error => err.to_s, :secret => request.POST["secret"]},
          layout: "layouts/form.html.erb".to_sym
        )
      end
    end

    def pretty_print_secret(secret)
      s = ""
      secret.split("").each_slice(4).with_index do |slice, i|
        s << slice.join
        if i == 3
          s << "<br>"
        elsif i < 7
          s << " "
        end
      end
      s
    end

    def qr_code(secret)
      url = ROTP::TOTP.new(secret).provisioning_uri("")
      "data:image/svg+xml;base64,#{Base64.encode64(RQRCode::QRCode.new(url).as_svg)}"
    end

  end # User

end
