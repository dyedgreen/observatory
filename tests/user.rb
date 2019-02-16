require "test/unit"

require "./classes/user.rb"


class TestUser < Test::Unit::TestCase

  def test_missing
    assert_raise AppError do
      User.new "does_not_exist"
    end
  end

  def test_invalid_create
    assert_raise(AppError) { User.create "invalid_name_\#", User.make_secret }
    assert_raise(AppError) { User.create "", nil }
    assert_raise(AppError) { User.create "", User.make_secret }
    assert_raise(AppError) { User.create "test", User.make_secret, "wrong-code" }
    assert_raise(AppError) { User.create "test", nil }
  end

  def test_create
    User.create "test", User.make_secret
    t = User.new "test"
    assert_equal t.name, "test"
  end

  def test_new
    a = User.new "test"
    b = User.new a.id
    assert_equal a, b
  end

  def test_exist
    assert_true User.exist? "test"
    assert_false User.exist? "peter-parker"
  end

  def test_list
    names = "abcdefg".split.map { |l| l*3 }
    names.each do |n|
      User.create n, User.make_secret
    end
    user_list = User.list
    names.each { |n| assert_true user_list.include? n }
  end

end
