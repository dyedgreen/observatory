require "test/unit"

require "./classes/track.rb"


class TestTrackEvent < Test::Unit::TestCase

  def setup
    Track::Url.create "tilman.xyz"
    @url = Track::Url.new "tilman.xyz"
  end

  def teardown
    @url.delete
  end

  def test_need_derived
    assert_raise { Track::Event.create @url }
    assert_raise { Track::Event.new 0 }
  end

  def test_create_from_url
    @url.record_event
    @url.record_event({
      "ref" => "some ref",
    })
    @url.record_event({
      "user_agent" => "a"*500,
    })
    assert_equal @url.events.count, 3
    assert_equal @url.events.first.resource, @url
    assert_true @url.events[1].ref == "some ref"
    assert_equal @url.events[2].user_agent, nil
  end

  def test_meta_keys
    ["ref", "user_agent"].each { |key| assert_true Track::Redirect.meta_keys.include? key }
    ["ref", "visit_duration", "screen_width", "screen_height"].each { |key| assert_true Track::View.meta_keys.include? key }
    ["token"].each { |key| assert_true Track::Visitor.meta_keys.include? key }
  end

end
