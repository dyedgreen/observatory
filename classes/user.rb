# Classes for user and login
# management

require "rotp"


class User

  attr_reader :name, :secret

  def initialize(name, secret=nil)
    @name = name.downcase
    @secret = secret
    if @secret
      $db.execute <<-SQL, [@name.to_s, @secret.to_s, Time.new.to_i]
        insert into users (name, secret, last_login) values (?, ?, ?)
      SQL
      @last_login = Time.new.to_i
    else
      user = $db.execute <<-SQL, [@name.to_s]
        select secret, last_login from users where name=? limit 1
      SQL
      raise ArgumentError, "User name does not exist" if user.count != 1
      @secret = user[0][0]
      @last_login = user[0][1]
    end
  end

  def valid?(code)
    User::valid? code, @secret
  end

  def update_secret(secret)
    $db.execute <<-SQL, [secret.to_s, @name.to_s]
      update users set secret=? where name=?
    SQL
  end

  class << self

    def exist?(name)
      $db.execute("select count(*) from users where name=?", [name.downcase])[0][0] == 1
    end

    def count
      $db.execute("select count(*) from users")[0][0]
    end

    def list
      $db.execute("select name from users")
    end

    def make_secret
      ROTP::Base32.random_base32
    end

    def valid?(code, secret)
      totp = ROTP::TOTP.new secret
      totp.verify code, drift_behind: 30
    end

  end
end # User
