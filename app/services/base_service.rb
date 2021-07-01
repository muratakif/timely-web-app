# frozen_string_literal: true

class BaseService
  attr_reader :errors

  def initialize(*args)
    @errors = []
    super
  end
end
