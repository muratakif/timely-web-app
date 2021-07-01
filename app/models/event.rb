# frozen_string_literal: true

class Event < ApplicationRecord
	belongs_to :user

  validates :gcalendar_id, uniqueness: true
end
