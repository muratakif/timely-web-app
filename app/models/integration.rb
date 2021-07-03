# frozen_string_literal: true

# Integrations model
class Integration < ApplicationRecord
  belongs_to :user

  enum status: {
    pending: 'pending',
    active: 'active',
    cancelled: 'cancelled',
    failed: 'failed',
    unauthorized: 'unauthorized'
  }, _prefix: true
end
