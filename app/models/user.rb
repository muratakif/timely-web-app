# frozen_string_literal: true

class User < ApplicationRecord
  has_many :events, dependent: :destroy
  has_many :tokens, dependent: :destroy

  def sync_events!
    SyncCalendarWorker.perform_async(id)
  end
end
