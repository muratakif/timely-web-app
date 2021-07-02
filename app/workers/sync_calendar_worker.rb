# frozen_string_literal: true

class SyncCalendarWorker
  include Sidekiq::Worker
  sidekiq_options queue: :calendar_setup, retry: 3

  # TODO: Add retry logic
  def perform(user_id)
    last_checked_in = User.select(:last_checked_in).find(user_id)&.last_checked_in
    service = Events::Sync.new(user_id, from: last_checked_in)
    service.call
  end
end
