# frozen_string_literal: true

class SyncAllCalendarsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :calendar_setup, retry: 3

  def perform(_user_id)
    User.where(has_synced: false).each do |user|
      SyncCalendarWorker.perform_async(user.id)
    end
  end
end
