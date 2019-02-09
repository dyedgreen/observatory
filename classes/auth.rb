require "scorched"
require "rotp"
require "rqrcode"
require "base64"


class User

  attr_reader :name, :secret

  def initialize(name, secret=nil)
    @name = name.downcase
    @secret = secret
    if @secret
      $db_user.execute <<-SQL, [@name.to_s, @secret.to_s, Time.new.to_i]
        insert into users (name, secret, last_login) values (?, ?, ?)
      SQL
      @last_login = Time.new.to_i
    else
      user = $db_user.execute <<-SQL, [@name.to_s]
        select secret, last_login from users where name=? limit 1
      SQL
      raise ArgumentError, "User name does not exist" if user.count != 1
      @secret = user[0][0]
      @last_login = user[0][1]
    end
  end

  def valid?(code)
    totp = ROTP::TOTP.new @secret
    totp.verify(code, drift_behind: 30)
  end

  def self.exist?(name)
    $db_user.execute("select count(*) from users where name=?", [name])[0][0] == 1
  end

  def self.count
    $db_user.execute("select count(*) from users")[0]
  end

  def self.list
    $db_user.execute("select name from users")
  end

end


class ProtectedController < Scorched::Controller

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

end


class UserController < ProtectedController

  render_defaults[:dir] = "./web"

  get "/" do
    user?
  end

  before match: "/register" do
    unless user?
      redirect "/login"
    end
  end

  get "/register" do
    render_register "", ROTP::Base32.random_base32, nil
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
    elsif User.exist? username
      error = "This username is taken."
    elsif !ROTP::TOTP.new(secret).verify(code, drift_behind: 30)
      error = "The code is invalid."
    end

    unless error
      User.new username, secret
      login username
      redirect "/", status: 300
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

end
