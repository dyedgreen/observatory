require "test/unit"

require "./classes/error.rb"


class TestError < Test::Unit::TestCase

  def test_type
    err = AppError.new "Hello World!"
    assert_true err.is_a?(RuntimeError)
    err = HiddenAppError.new "This is private!"
    assert_true err.is_a?(RuntimeError)
  end

  def test_message
    err = AppError.new "Hello World!"
    assert_equal "Hello World!", err.to_s
    assert_equal "AppError: Hello World!", err.inspect
  end

  def test_hidden
    err = HiddenAppError.new "Private message!"
    assert_true err.to_s != "Private message!"
    assert_equal "AppError: Private message!", err.inspect
  end

end
