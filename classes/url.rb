# Classes for managing
# url resources

require "securerandom"
require "browser"

require "./classes/error.rb"
require "./classes/plot.rb"


class Url

  ERR_EXISTS     = "Url already exists."
  ERR_NOT_EXISTS = "Url does not exist."
  ERR_BAD_TARGET = "Target is not a well-formed url."

  PUBLIC_ID = /\A[a-zA-Z0-9]{8}\Z/

  attr_reader :id, :public_id, :target, :created

  # Initialize the url resource
  # either by id, public_id, or target
  def initialize(id_or_target)
    q = "select id, public_id, target, created from urls where "
    if id_or_target.is_a? Integer
      q << "id = ?"
    elsif id_or_target.match PUBLIC_ID
      q << "public_id like ?"
    else
      q << "target like ?"
    end
    row = $db.execute(q, [id_or_target])
    raise AppError.new ERR_NOT_EXISTS unless row.count > 0
    @id = row[0][0]
    @public_id = row[0][1]
    @target = row[0][2]
    @created = Time.at row[0][3]
    @hits = nil
  end

  def ==(other)
    return false unless other.is_a? Url
    @id == other.id
  end

  def delete
    $db.execute "delete from url_hits where url = ?", [@id]
    $db.execute "delete from urls where id = ?", [@id]
  end

  def hit(meta={})
    UrlHit.create self, meta
  end

  def hits
    unless @hits
      @hits = UrlHitArray.new self
    end
    @hits
  end

  alias_method :to_s, :target

  class << self

    def valid?(url)
      # This is a loose approximation
      url.match /(https?:\/\/)?([a-zA-Z0-9]+\.)?[a-zA-Z0-9]+\.[a-zA-Z0-9]{2,}(\/.*)*/
    end

    def exist?(id)
      q = "select count(*) from urls where "
      if id.is_a? Integer
        q << "id = ?"
      elsif id.match PUBLIC_ID
        q << "public_id like ?"
      else
        q << "target like ?"
      end
      $db.execute(q, [id])[0][0] > 0
    end

    def create(target)
      raise AppError.new ERR_BAD_TARGET unless valid? target
      raise AppError.new ERR_EXISTS if exist? target
      $db.execute <<-SQL, [SecureRandom.alphanumeric(8), target.to_s, Time.new.to_i]
        insert into urls (public_id, target, created) values (?, ?, ?)
      SQL
      self.new target
    end

    def list(limit=nil, page=0)
      if limit
        # If limit is given, return list and total page count
        rows = $db.execute "select id from urls order by created desc limit ? offset ?", [limit, page*limit]
        total = $db.execute("select count() from urls")[0][0]
        rows = rows.map { |row| Url.new row[0] }
        [rows, total % limit == 0 ? total / limit : total / limit + 1]
      else
        rows = $db.execute "select id from urls order by created desc"
        rows.map { |row| Url.new row[0] }
      end
    end

    alias_method :all, :list

  end
end # Url

class UrlHit

  META_KEYS = ["ref", "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content", "user_agent"]

  attr_reader :id, :url, :created
  attr_reader :ref, :utm_source, :utm_medium, :utm_campaign, :utm_term, :utm_content, :user_agent
  attr_reader :browser

  def initialize(id)
    row = $db.execute <<-SQL, [id]
      select
        url, ref, utm_source, utm_medium, utm_campaign, utm_term, utm_content, user_agent, created
      from url_hits where id = ? limit 1
    SQL
    @id = id
    @url = row[0][0]
    @ref = row[0][1]
    @utm_source = row[0][2]
    @utm_medium = row[0][3]
    @utm_campaign = row[0][4]
    @utm_term = row[0][5]
    @utm_content = row[0][6]
    @user_agent = row[0][7]
    @browser = Browser.new @user_agent
    @created = Time.at row[0][8]
  end

  def <=>(other)
    raise ArgumentError unless other.is_a? UrlHit
    @created <=> other.created
  end

  class << self

    def create(url, meta={})
      url = Url.new url unless url.is_a? Url
      q = "insert into url_hits (url, created"
      q_params = [url.id, Time.new.to_i]
      meta.keys.each do |key|
        if META_KEYS.include? key.to_s
          q << ",#{key.to_s}"
          q_params.push meta[key].to_s
        end
      end
      q << ") values (#{'?,' * (q_params.count - 1)} ?)"
      $db.execute q, q_params
    end

  end
end # UrlHit

class UrlHitArray

  include Enumerable

  def initialize(url)
    raise ArgumentError unless url.is_a? Url
    @url = url
  end

  def each
    load_hits
    @hits.each { |hit| yield hit }
  end

  def [](*args)
    load_hits
    @hits.[](*args)
  end

  def first
    return nil if count == 0
    unless @first
      row = $db.execute <<-SQL, [@url.id]
        select id from url_hits where url = ? order by created asc limit 1
      SQL
      @first = UrlHit.new row[0][0]
    end
    @first
  end

  def last
    return nil if count == 0
    unless @last
      row = $db.execute <<-SQL, [@url.id]
        select id from url_hits where url = ? order by created desc limit 1
      SQL
      @last = UrlHit.new row[0][0]
    end
    @last
  end

  def count(bin_size=nil)
    # bin_size is given in seconds
    if bin_size
      rows = $db.execute <<-SQL, [@url.id, bin_size]
        select count(), created from url_hits where url = ? group by created/? order by created asc
      SQL
      return rows.map { |row| [row[0], Time.at(row[1])] }
    end
    @count = $db.execute("select count() from url_hits where url = ?", [@url.id])[0][0] unless @count
    @count
  end

  def aggregate(meta_field)
    browser = false
    if meta_field == "browser"
      meta_field = "user_agent"
      browser = true
    end
    raise ArgumentError unless UrlHit::META_KEYS.include? meta_field
    rows = $db.execute(
      "select #{meta_field}, count() from url_hits where url = ? group by #{meta_field}", 
      [@url.id]
    )
    elems = Hash.new 0
    rows.each do |row|
      if browser
        elems[Browser.new(row[0]).name] += row[1]
        next
      end
      next if row.first == nil
      elems[row[0]] = row[1]
    end
    return elems
  end

  def plot(color:'000000')
    unless @plot
      day_in_s = 24 * 60 * 60
      data = count day_in_s
      x = data.map { |el| (el[1].to_i - data.first[1].to_i) / day_in_s }
      y = data.map { |el| el.first }
      x.insert 0, x.first
      y.insert 0, 0
      @plot = Plot::Line.new x, y, color: color
    end
    @plot
  end

  alias_method :length, :count
  alias_method :size, :count

  private

  def load_hits
    unless @hits
      rows = $db.execute <<-SQL, [@url.id]
        select id from url_hits where url = ? order by created asc
      SQL
      @hits = rows.map { |row| UrlHit.new row[0] }
    end
  end

end #UrlHitArray

class Referral

  def initialize(str)
    @str = str
  end

  def urls
    unless @urls
      rows = $db.execute <<-SQL, [@str]
        select url from url_hits where ref like ? group by url
      SQL
      @urls = rows.map { |row| Url.new row[0] }
    end
    @urls
  end

  def to_s
    @str
  end

  class << self

    def list
      rows = $db.execute "select ref from url_hits group by ref"
      res = Array.new
      rows.reject{ |row| row[0] == nil }.map{ |row| Referral.new row[0] }
    end

    alias_method :all, :list

  end
end # Referral
