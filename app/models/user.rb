# frozen_string_literal: true

# User model
class User < ApplicationRecord
  has_many :events, dependent: :destroy
  has_many :integrations, dependent: :destroy
  has_many :tokens, dependent: :destroy

  def sync_events!
    SyncCalendarWorker.perform_async(id)
  end
end
