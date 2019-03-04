require "securerandom"
require "browser"
require "open-uri"

require "./classes/error.rb"
require "./classes/plot.rb"


module Track

  class Url
    # Url resource that points
    # to some target url and can
    # track redirects.

    ERR_EXISTS      = "Url already exists."
    ERR_NOT_EXISTS  = "Url does not exist."
    ERR_BAD_TARGET  = "Url target is not a well-formed url."
    ERR_LONG_TARGET = "Url target is too long."

    PUBLIC_ID      = /\A[a-zA-Z0-9]{8}\Z/
    MAX_TARGET_LEN = 256

    attr_reader :id, :public_id, :target, :created

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
      # Caches
      @cache_events = nil
    end

    def ==(other)
      return false unless other.is_a? Url
      @id == other.id
    end

    def events(cache=true)
      @cache_events = EventArray.new self, Redirect if cache && !@cache_events
      return @cache_events
    end

    def record_event(meta={})
      Redirect.create self, meta
    end

    def target_with_protocol
      (@target.match(/\Ahttps?:\/\//) ? "" : "http://") << @target
    end

    def delete
      Redirect.delete self
      $db.execute "delete from urls where id = ?", [@id]
    end

    def self.create(target)
      raise AppError.new ERR_BAD_TARGET unless valid? target
      raise AppError.new ERR_LONG_TARGET if target.length > MAX_TARGET_LEN
      raise AppError.new ERR_EXISTS if exist? target
      $db.execute <<-SQL, [SecureRandom.alphanumeric(8), target.to_s, Time.now.to_i]
        insert into urls (public_id, target, created) values (?, ?, ?)
      SQL
      self.new target
    end

    def self.exist?(id_or_target)
      q = "select count(*) from urls where "
      if id_or_target.is_a? Integer
        q << "id = ?"
      elsif id_or_target.match PUBLIC_ID
        q << "public_id like ?"
      else
        q << "target like ?"
      end
      $db.execute(q, [id_or_target])[0][0] > 0
    end

    # Ordered such that last created is
    # at index 0.
    def self.list(limit=nil, page=0)
      if limit
        rows = $db.execute "select id from urls order by created desc limit ? offset ?", [limit, page*limit]
      else
        rows = $db.execute "select id from urls order by created desc"
      end
      rows.map { |row| Url.new row[0] }
    end

    # If using list with a limit, knowing
    # the total page count is helpful.
    def self.count(page_size=1)
      total = $db.execute("select count() from urls")[0][0]
      return total % page_size == 0 ? total / page_size : total / page_size + 1
    end

    class << self
      alias_method :all, :list
    end

    def self.valid?(url)
      # This is an approximation
      url.match /\A(https?:\/\/)?([a-zA-Z0-9]+\.)?[a-zA-Z0-9\-\_]+\.[a-zA-Z0-9]{2,}(\/[^ \/]*)*\Z/
    end
  end # Url

  class Site
    # White list entry,
    # containing a hostname
    # and a consent token.

    ERR_EXISTS     = "Site already exists."
    ERR_NOT_EXISTS = "Site does not exist."

    CONSENT_TAG = /\<meta *name *= *["']observatory["'] *content *= *["']([a-zA-Z0-9]{16})["'] *\/? *\>/i

    attr_reader :id, :host, :consent_token

    def initialize(id_or_host)
      q = "select id, host, consent_token from site_whitelist where "
      if id_or_host.is_a? Integer
        q << "id = ?"
      else
        q << "host like ?"
      end
      q << " limit 1"
      row = $db.execute q, [id_or_host]
      raise AppError.new ERR_NOT_EXISTS unless row.count > 0
      @id = row.first[0]
      @host = row.first[1]
      @consent_token = row.first[2]
    end

    def ==(other)
      return false unless other.is_a? Site
      return @id == other.id
    end

    def consent?(path)
      begin
        open("http://#{@host}#{path}", "User-Agent" => "Ruby/Observatory") do |doc|
          body = doc.read(2048)
          token = CONSENT_TAG.match(body)
          token ? token[1] == @consent_token : false
        end
      rescue SocketError
        # Not reachable -> no consent
        return false
      end
    end

    def delete
      $db.execute("delete from site_whitelist where id = ?", [@id])
    end

    def self.exist?(host)
      $db.execute("select count(*) from site_whitelist where host like ?", [host])[0][0] == 1
    end

    def self.create(host)
      raise AppError.new ERR_EXISTS if exist? host
      $db.execute <<-SQL, [host, SecureRandom.alphanumeric(16)]
        insert into site_whitelist (host, consent_token) values (?, ?)
      SQL
      Site.new host
    end
  end

  class Page
    # Page on website using
    # observatory. Tracks
    # page views.

    ERR_EXISTS     = "Page already exists."
    ERR_NOT_EXISTS = "Page does not exist."
    ERR_BAD_HOST   = "Host is not on white-list."
    ERR_NO_CONSENT = "Consent token not present."

    def initialize(id_or_host, path=nil)
      q = "select id, site, path from pages where "
      if id_or_host.is_a? Integer
        q << "id = ?"
      else
        q << "site = (select id from site_whitelist where host like ?) and path like ?"
      end
      q << " limit 1"
      row = $db.execute(q, id_or_host.is_a?(Integer) ? [id_or_host] : [id_or_host, path])
      p row
    end

    def self.create
    end

    def self.create_site(host)

    end
  end # Page

  class Event
    # Tracking event, these are the
    # same for pages and urls, the
    # only difference may be in how
    # they are loaded from the database.

    META_KEYS = ["ref", "user_agent"]
    MAX_META_LEN = 256

    attr_reader :id, :resource, :created
    attr_reader :ref, :user_agent

    def initialize(id)
      row = $db.execute <<-SQL, [id]
        select
        resource, created, ref, user_agent
        from #{TABLES[self.class]}
        where id = ? limit 1
      SQL
      raise ArgumentError unless row.count > 0
      @id = id
      @resource     = RESOURCES[self.class].new row[0][0]
      @created      = Time.at row[0][1]
      @ref          = row[0][2]
      @user_agent   = row[0][3]
    end

    def browser
      Browser.new @user_agent
    end

    def ==(other)
      @id == other.id
    end

    def <=>(other)
      raise ArgumentError unless other.is_a? Event
      @created <=> other.created
    end

    def self.create(resource, meta={})
      q = "insert into #{TABLES[self]} (resource, created"
      q_params = [resource.id, Time.now.to_i]
      meta.keys.each do |key|
        if self.meta_keys.include?(key.to_s) && meta[key].to_s.length <= MAX_META_LEN
          q << ", #{key.to_s}"
          q_params.push meta[key].to_s
        end
      end
      q << ") values (#{'?,'*(q_params.count-1)}?)"
      $db.execute q, q_params
    end

    def self.delete(resource)
      $db.execute "delete from #{TABLES[self]} where resource = ?", [resource.id]
    end

    def self.meta_keys
      META_KEYS
    end
  end # Event

  class EventArray
    # Enumerable object that
    # implements read access
    # to a resources events.
    # Db reads are cached for
    # nice api ergonomics.
    # Notice that this is intended
    # for short usage, since the
    # cache may be invalidated
    # at any time.
    #
    # Array is ordered such that
    # created is increasing from 0
    # to last.

    include Enumerable

    def initialize(resource, event_class)
      raise ArgumentError unless Event::TABLES.keys.include? event_class
      @resource = resource
      @type = event_class
      # Caches
      @cache_all = nil
      @cache_index = Hash.new
    end

    def each
      load_all
      @cache_all.each { |el| yield el }
    end

    def [](*args)
      if args.count == 1 && !@cache_all
        unless @cache_index[args.first]
          rows = $db.execute(
            "select id from #{Event::TABLES[@type]} where resource = ? order by created asc limit 1 offset ?",
            [@resource.id, args.first]
          )
          @cache_index[args.first] = @type.new rows.first[0] unless rows.count == 0
        end
        @cache_index[args.first]
      else
        load_all
        @cache_all.[](*args)
      end
    end

    def count
      $db.execute("select count(*) from #{Event::TABLES[@type]} where resource = ?", [@resource.id])[0][0]
    end

    def first
      self[0]
    end

    def last
      self[count-1]
    end

    def aggregate(meta_field)
      key = meta_field == "browser" ? "user_agent" : meta_field
      raise ArgumentError unless @type.meta_keys.include?(key)
      rows = $db.execute(
        "select #{key}, count() from #{Event::TABLES[@type]} where resource = ? group by #{key}",
        [@resource.id]
      )
      counts = Hash.new 0
      rows.each do |row|
        next unless row[0] || meta_field == "browser" # skip empty
        counts[meta_field == "browser" ? Browser.new(row[0]): row[0]] += row[1]
      end
      return counts
    end

    # Count items in bins, where
    # the bin-size if given in
    # seconds.
    def bins(bin_size=24*60*60)
      rows = $db.execute(
        "select count(), created from #{Event::TABLES[@type]} where resource = ? group by created/? order by created asc",
        [@resource.id, bin_size]
      )
      return rows.map { |row| [row[0], Time.at(row[1])] }
    end

    def plot(color:'000000')
      data = bins
      x, y = [], []
      data.count.times do |i|
        x.push data[i][1].to_i
        y.push data[i][0]
      end
      x.insert 0, x.first
      y.insert 0, 0
      Plot::Line.new x, y, color: color
    end

    private
    def load_all
      unless @cache_all
        rows = $db.execute(
          "select id from #{Event::TABLES[@type]} where resource = ? order by created asc",
          [@resource.id]
        )
        @cache_all = rows.map { |row| @type.new row[0] }
      end
      @cache_all
    end
  end

  class Redirect < Event
    # Redirect to url. This
    # event type does not add
    # any additional fields.
  end # Redirect

  class View < Event
    # Page view event
    # TODO
  end # View

  # Specify tables and
  # resource classes
  class Event
    TABLES = {
      Redirect => "redirects",
      View     => "views",
    }
    RESOURCES = {
      Redirect => Url,
      View     => Page,
    }
  end

end
