# Classes for user and login
# management

require "rotp"
require "./classes/error.rb"


class User

  ERR_EXISTS     = "User already exists."
  ERR_NOT_EXISTS = "User does not exist."
  ERR_LOGIN_CODE = "The login code is not valid."
  ERR_BAD_NAME   = "The name is not valid."

  attr_reader :id, :name, :secret, :last_login

  def initialize(name_or_id)
    name_or_id = name_or_id.downcase if name_or_id.class == String
    q = "select id, name, secret, last_login from users where "
    q << (name_or_id.class == Integer ? "id" : "name")
    q << " = ? limit 1"
    row = $db.execute q, [name_or_id]
    raise AppError.new ERR_NOT_EXISTS unless row.count == 1
    @id = row.first[0]
    @name = row.first[1]
    @secret = row.first[2]
    @last_login = row.first[3]
  end

  def valid?(code)
    # Validate code
    User::valid? code, @secret
  end

  def login(code)
    # Validate code, and update last_login
    # if successful, raises an error
    raise AppError.new ERR_LOGIN_CODE unless valid? code
    $db.execute <<-SQL, [Time.new.to_i, @id]
      update users set last_login = ? where id = ?
    SQL
  end

  def update_secret(secret, code=nil)
    raise AppError.new ERR_LOGIN_CODE unless code == nil || User.valid?(code, secret)
    $db.execute <<-SQL, [secret.to_s, @name.to_s]
      update users set secret = ? where name = ?
    SQL
  end

  class << self

    def valid?(code, secret)
      totp = ROTP::TOTP.new secret
      totp.verify code, drift_behind: 15
    end

    def exist?(name)
      $db.execute("select count(*) from users where name = ?", [name.downcase])[0][0] == 1
    end

    def count
      $db.execute("select count(*) from users")[0][0]
    end

    def list
      $db.execute("select name from users").map { |row| row.first }
    end

    def create(name, secret, code=nil)
      # If code is given, this will
      # verify and raise on error
      name.downcase!
      raise AppError.new ERR_EXISTS if exist? name
      raise AppError.new ERR_BAD_NAME unless name.match /\A[a-z0-9-_.]{3,}\Z/
      raise AppError.new ERR_LOGIN_CODE unless code == nil || valid?(code, secret)
      $db.execute <<-SQL, [name, secret, Time.new.to_i]
        insert into users (name, secret, last_login) values (?, ?, ?)
      SQL
      User.new name
    end

    def make_secret
      ROTP::Base32.random_base32
    end

  end
end # User
