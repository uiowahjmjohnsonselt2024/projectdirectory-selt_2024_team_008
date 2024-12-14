class Tile < ApplicationRecord
  belongs_to :game
  belongs_to :occupant_user, class_name: "User", foreign_key: "occupant_id", optional: true

  validates :x, :y, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validates :image_source, presence: true, allow_nil: true
  validates :task_type, inclusion: { in: %w[MATH NPC TIC],
                                     message: "%{value} is not a valid task type"}, allow_nil: true

  # Fetch occupant avatar image
  def occupant_avatar
    if occupant_user&.avatar&.avatar_image
      "data:image/png;base64,#{Base64.strict_encode64(occupant_user.avatar.avatar_image)}"
    else
      ActionController::Base.helpers.asset_path('defaultAvatar.png')
    end
  end

end