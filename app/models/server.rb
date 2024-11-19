# frozen_string_literal: true

class Server < ApplicationRecord
  belongs_to :creator, class_name: 'User'
  has_many :memberships
  has_many :joined_servers, through: :memberships, source: :server
  has_many :messages
end
