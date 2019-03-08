require "test/unit"

require "./classes/track.rb"

# Stub for testing consent of sites
$sys_open = method :open
def open(*args, &block)
  case args.first
  when /https?:\/\/stub.give.consent\/.*/i
    block.call StringIO.new <<-HTML
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <title>We give consent!</title>
          <meta name="observatory" content="#{$stub_consent_token}">
        </head>
        <body>
          <h1>Consent here!</h1>
        </body>
      </html>
    HTML
  else
    $sys_open.call(*args, &block)
  end
end

class TestTrackPage < Test::Unit::TestCase

  def setup
    host = "www.google.com"
    @google = Track::Site.exist?(host) ? Track::Site.new(host) : Track::Site.create(host)
    host = "can.not.be.reached"
    @not_reachable = Track::Site.exist?(host) ? Track::Site.new(host) : Track::Site.create(host)
    host = "stub.give.consent"
    @give_consent = Track::Site.exist?(host) ? Track::Site.new(host) : Track::Site.create(host)
    $stub_consent_token = @give_consent.consent_token
    @site = @give_consent
  end

  def test_site_new
    assert_equal Track::Site.new("www.google.com"), @google
    assert_equal Track::Site.new(@google.id), @google
    assert_raise(AppError) { Track::Site.new("does.not.exist") }
  end

  def test_site_create
    a = Track::Site.create "tilman.xyz"
    assert a.is_a? Track::Site
    b = Track::Site.new "tilman.xyz"
    assert_equal a, b
  end

  def test_site_consent
    assert_false @google.consent? "/"
    assert_false @not_reachable.consent? "/"
    # Use stub to test positive case
    assert_true @give_consent.consent? "/"
    $stub_consent_token = @give_consent.consent_token.swapcase
    assert_false @give_consent.consent? "/"
  end

  def test_site_delete
    @google.delete
    assert_false Track::Site.exist? "www.google.com"
    assert_raise(AppError) { Track::Site.new("www.google.com") }
  end

  def test_page_create
    a = Track::Page.create @site.host, "/a"
    b = @site.create_page "/b"
    assert_true Track::Page.exist? @site, "/a"
    assert_true Track::Page.exist? @site.host, "/a"
    assert_true Track::Page.exist? @site, "/b"

    assert_raise(AppError) { @google.create_page "/no-consent-given" }
  end

  def test_page_new
    page = @site.create_page "/new"
    assert_equal Track::Page.new(page.id), page
    assert_equal Track::Page.new(page.site, "/new"), page
    assert_equal Track::Page.new(@site.host, "/new"), page
  end

  def test_site_record_visitor
  # TODO: Test other stuff in api before building json
  #   api and UI + ts parts

end
