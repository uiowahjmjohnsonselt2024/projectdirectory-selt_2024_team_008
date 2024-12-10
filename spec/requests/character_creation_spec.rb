require 'rails_helper'

RSpec.describe "CharacterCreations", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/character_creation/index"
      expect(response).to have_http_status(:success)
    end
  end

end
