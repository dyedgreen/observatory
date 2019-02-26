# Custom exceptions


class AppError < RuntimeError
  # Error type for errors raised
  # within the business logic. Any
  # custom error types should subclass
  # this.

  # Any method exposed to the user should
  # raise an AppError on error / invalid input
  # which will then be passed on to the user.

  def initialize(description)
    @description = description.to_s
  end

  def to_s
    @description
  end

  def inspect
    "AppError: #{@description}"
  end
end # AppError

class HiddenAppError < AppError
  # Error that hides the description,
  # when used as a string in a view.

  def to_s
    "An error occurred."
  end
end # HiddenAppError
