require './config/boot'
require './config/environment'

include Clockwork

every(30.minutes, 'calendar_sync') do
  SyncAllCalendarsWorker.perform_async
end
