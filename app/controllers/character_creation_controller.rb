require 'open-uri'
class CharacterCreationController < ApplicationController
  def index
    @avatar = current_user.avatar
    @user_items = current_user.user_items.includes(:item)
  end

  def equip_item
    avatar = current_user.avatar
    item = Item.find(params[:item_id])

    case item.item_type
    when 'hat'
      avatar.update(hat_id: item.id)
    when 'top'
      avatar.update(top_id: item.id)
    when 'bottoms'
      avatar.update(bottoms_id: item.id)
    when 'shoes'
      avatar.update(shoes_id: item.id)
    when 'accessories'
      avatar.update(accessories_id: item.id)
    end

    redirect_to character_creation_index_path, notice: "#{item.item_name} has been equipped!"
  end

  def unequip_item
    avatar = current_user.avatar
    slot = params[:slot]

    if %w[hat top bottoms shoes accessories].include?(slot)
      avatar.update("#{slot}_id" => nil)
      redirect_to character_creation_index_path, notice: "#{slot.capitalize} has been unequipped!"
    else
      redirect_to character_creation_index_path, alert: "Invalid slot!"
    end
  end

  def generate_avatar
    avatar = current_user.avatar

    begin
      image_data = generate_avatar_image(avatar)

      avatar.update!(avatar_image: image_data)
      Rails.logger.debug "Avatar updated with new image: #{avatar.avatar_image.present?}"

      redirect_to character_creation_index_path, notice: "Avatar successfully generated!"
    rescue => e
      Rails.logger.error "Failed to generate avatar: #{e.message}"
      redirect_to character_creation_index_path, alert: "Failed to generate avatar: #{e.message}"
    end
  end

  private

  def generate_avatar_image(avatar)
    hat = avatar.hat&.item_name || "no hat"
    top = avatar.top&.item_name || "grey top"
    bottoms = avatar.bottoms&.item_name || "grey bottoms"
    shoes = avatar.shoes&.item_name || "grey shoes"
    accessories = avatar.accessories&.item_name || "no accessories"


    client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])

    response = client.images.generate(
      parameters: {
        prompt: "Generate an image of a pixel art character with a white background and no face. THEY MUST BE WEARING THE FOLLOWING #{hat}, #{top}, #{bottoms}, #{shoes}, #{accessories}.",
        n: 1,
        size: "256x256"
      }
    )

    if response["data"] && response["data"][0]["url"]
      # Fetch image data from the generated URL
      image_url = response["data"][0]["url"]
      URI.parse(image_url).open.read
    else
      raise "Image generation failed: #{response['error']['message'] || 'Unknown error'}"
    end
  end
end
