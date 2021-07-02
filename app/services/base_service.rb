# frozen_string_literal: true

# Base service class
class BaseService
  attr_reader :errors

  def initialize(*args)
    @errors = []
    super
  end
end
