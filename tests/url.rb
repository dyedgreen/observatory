# TODO: DELETE


require "test/unit"

require "./classes/url.rb"


class TestUrl < Test::Unit::TestCase

  def test_valid
    assert_true !!Url.valid?("https://tilman.xyz")
    assert_true !!Url.valid?("www.google.com")
    assert_true !!Url.valid?("google.co.uk")
    assert_true !!Url.valid?("https://en.wikipedia.org/wiki/UTM_parameters")
    assert_true !!Url.valid?("https://www.youtube.com/watch?v=uqKGREZs6-w")
  end

  def test_invalid
    assert_false !!Url.valid?("Hello World!")
    assert_false !!Url.valid?("wwwcatscom")
    assert_false !!Url.valid?("The quick brown fox jumps over the lazy dog.")
    # assert_false !!Url.valid?("peter.parker@gmail.com") - not covered by approximation
  end

  def test_create
    Url.create "www.google.com"
    assert_true Url.exist? "www.google.com"
  end

  def test_new
    a = Url.create "www.peter-parker.com"
    b = Url.new "www.peter-parker.com"
    c = Url.new a.id
    d = Url.new a.public_id
    assert_equal a, b
    assert_equal b, c
    assert_equal c, d
  end

  def test_equal
    a = Url.create "www.wikipedia.org"
    assert_true a == a
    assert_false a == "wikipedia"
  end

  def test_invalid_create
    assert_raise(AppError) { Url.create "hello world" }
    Url.create "tilman.xyz"
    assert_raise(AppError) { Url.create "tilman.xyz" }
  end

  def test_exist
    Url.create "www.tilman.xyz"
    assert_true Url.exist? "www.tilman.xyz"
    assert_false Url.exist? "e = mc**2"
  end

  def test_list
    urls = "abcdefg".split("").map { |l| "www.#{l}.com" }
    urls.each { |u| Url.create u }
    list = Url.list
    urls.each { |u| assert_true list.any? { |url| u == url.target } }
  end

  def test_paginated_list
    urls = "hijklmnopqrstuvw".split("").map { |l| "www.#{l}.com" }
    urls.each { |u| Url.create u }
    list_a = Url.list 8, 0
    list_b = Url.list 8, 1
    assert_equal 8, list_a[0].count
    assert_equal 8, list_b[0].count
    assert_equal list_a[0], list_a[0] - list_b[0]
  end

end
