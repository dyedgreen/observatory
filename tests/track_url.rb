require "test/unit"

require "./classes/track.rb"


class TestTrackUrl < Test::Unit::TestCase

  def test_create_and_new
    url = Track::Url.create "https://tilman.xyz"
    url_a = Track::Url.new "https://tilman.xyz"
    url_b = Track::Url.new url.id
    url_c = Track::Url.new url.public_id

    assert_equal url.id, url_a.id
    assert_equal url_a, url_b
    assert_equal url_b.target, "https://tilman.xyz"
    assert_equal url_a, url_c
    assert_equal url, url_a
  end

  def test_equal
    url = Track::Url.create "www.equal.com"
    a = Track::Url.new "www.equal.com"
    b = Track::Url.new url.id
    assert_true a == b
  end

  def test_delete
    url = Track::Url.create "www.delete.com"
    assert_equal url, Track::Url.new("www.delete.com")
    url.delete
    assert_raise(AppError) { Track::Url.new "www.delete.com" }
  end

  def test_valid
    assert_true !!Track::Url.valid?("https://tilman.xyz")
    assert_true !!Track::Url.valid?("www.google.com")
    assert_true !!Track::Url.valid?("google.co.uk")
    assert_true !!Track::Url.valid?("https://en.wikipedia.org/wiki/UTM_parameters")
    assert_true !!Track::Url.valid?("https://www.youtube.com/watch?v=uqKGREZs6-w")
    assert_true !!Track::Url.valid?("www.rust-lang.org")
    assert_true !!Track::Url.valid?("www.youtube.co.uk")
  end

  def test_invalid
    assert_false !!Track::Url.valid?("Hello World!")
    assert_false !!Track::Url.valid?("wwwcatscom")
    assert_false !!Track::Url.valid?("The quick brown fox jumps over the lazy dog.")
    assert_false !!Track::Url.valid?("www.stack overflow.com")
    # assert_false !!Track::Url.valid?("peter.parker@gmail.com") - not covered by approximation
  end

  def test_huge_url
    assert_raise(AppError) { Track::Url.create "www." + ("a"*500) + ".com" }
  end

  def test_exist
    Track::Url.create "www.tilman.xyz"
    assert_true Track::Url.exist? "www.tilman.xyz"
    assert_false Track::Url.exist? "e = mc**2"
  end

  def test_list
    urls = "abcdefg".split("").map { |l| "www.#{l}.com" }
    urls.each { |u| Track::Url.create u }
    list = Track::Url.list
    urls.each { |u| assert_true list.any? { |url| u == url.target } }
  end

  def test_list_ref
    a = Track::Url.create "www.ref-a.com"
    b = Track::Url.create "www.ref-b.com"
    a.record_event({
      "ref" => "ref-a",
    })
    a.record_event({
      "ref" => "ref-b",
    })
    b.record_event({
      "ref" => "ref-a",
    })
    list_a = Track::Url.all(ref: "ref-a")
    list_b = Track::Url.all(ref: "ref-b")
    assert_true list_a.include? a
    assert_true list_a.include? b
    assert_true list_b.include? a
    assert_false list_b.include? b
  end

  def test_all
    assert_equal Track::Url.method(:list), Track::Url.method(:all)
  end

  def test_paginated_list
    urls = "hijklmnopqrstuvw".split("").map { |l| "www.#{l}.com" }
    urls.each { |u| Track::Url.create u }
    list_a = Track::Url.list 8, 0
    list_b = Track::Url.list 8, 1
    assert_equal 8, list_a.count
    assert_equal 8, list_b.count
    assert_equal list_a, list_a - list_b
  end

  def test_count
    total = Track::Url.count
    pages = Track::Url.count 2
    assert_true total == pages * 2 || total == pages * 2 - 1
  end

  def test_count_ref
    c = Track::Url.create "www.ref-c.com"
    d = Track::Url.create "www.ref-d.com"
    c.record_event({
      "ref" => "ref-c",
    })
    c.record_event({
      "ref" => "ref-d",
    })
    d.record_event({
      "ref" => "ref-c",
    })
    assert_equal 2, Track::Url.count(ref: "ref-c")
    assert_equal 1, Track::Url.count(ref: "ref-d")
  end

end
