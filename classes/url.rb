# Classes for managing
# url resources

require 'securerandom'


class Url

  attr_reader :id, :public_id, :target, :created

  # Initialize the url resource
  # either by id or by public_id
  def initialize(id)
    q = "select id, public_id, target, created from urls where "
    if id.class == Integer
      q << "id = ?"
    elsif id.match /\A[a-zA-Z0-9]{8}\Z/
      q << "public_id like ?"
    else
      q << "target like ?"
    end
    row = $db.execute(q, [id])
    raise ArgumentError, "Url #{id} does not exist" unless row.count > 0
    @id = row[0][0]
    @public_id = row[0][1]
    @target = row[0][2]
    @created = Time.new row[0][3]
  end

  alias_method :to_s, :target

  class << self

    def valid?(url)
      # This is a loose approximation
      url.match /(https?:\/\/)?([a-zA-Z0-9]+\.)?[a-zA-Z0-9]+\.[a-zA-Z0-9]{2,}(\/.*)*/
    end

    def exist?(id)
      q = "select count(*) from urls where "
      if id.class == Integer
        q << "id = ?"
      elsif id.match /\A[a-zA-Z0-9]{8}\Z/
        q << "public_id like ?"
      else
        q << "target like ?"
      end
      $db.execute(q, [id])[0][0] > 0
    end

    def create(target)
      raise ArgumentError, "Invalid url target" unless valid? target
      raise ArgumentError, "Target already exists" if exist? target
      $db.execute <<-SQL, [SecureRandom.alphanumeric(8), target.to_s, Time.new.to_i]
        insert into urls (public_id, target, created) values (?, ?, ?)
      SQL
      self.new target
    end

    def list
      $db.execute("select id from urls").map {|row| row[0]}
    end

    alias_method :all, :list

  end
end # Url
