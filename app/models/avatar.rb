class Avatar < ApplicationRecord
  belongs_to :user
  belongs_to :hat, class_name: "Item", optional: true
  belongs_to :top, class_name: "Item", optional: true
  belongs_to :bottoms, class_name: "Item", optional: true
  belongs_to :accessories, class_name: "Item", optional: true

  def avatar_image_base64
    return nil unless avatar_image
    Base64.encode64(avatar_image)
  end

  def avatar_image_base64=(base64_str)
    self.avatar_image = Base64.decode64(base64_str)
  end

  def description
    "Hat: #{hat&.name || 'None'}, Top: #{top&.name || 'None'}, Bottoms: #{bottoms&.name || 'None'}, Accessories: #{accessories&.name || 'None'}"
  end
end
