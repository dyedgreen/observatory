require "scorched"
require "rotp"
require "rqrcode"


class User

  attr_reader :name, :secret

  def new(name, secret=nil)
    @name = name
    @secret = secret
    if @secret
      $db_user.execute <<-SQL, [@name.to_s, @secret.to_s, Time.new.to_i]
        insert into users (name, secret, last_login) values (?, ?, ?)
      SQL
      @last_login = 0 # Allow login
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
    totp.verify_with_drift(code, 30)
  end

  def self.exists?(name)
    $db_user.execute("select count(*) from users where name=?", [name])[0] == 1
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
    session["user"] = user
  end

  def logout
    session["user"] = nil
  end

end


class UserController < ProtectedController

  render_defaults[:dir] = "./web"

  get "/register" do
    render "register.html.erb".to_sym, locals: {
      :qr_secret => RQRCode::QRCode.new("https://tilman.xyz").as_svg,
      :secret => "very secret",
      :username => ""
    }
  end

end
