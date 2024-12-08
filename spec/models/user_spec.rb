# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  let!(:mystery_box) { create(:item, item_name: "Mystery Box", item_type: "box", item_attributes: {}) }

  describe "Validations" do
    it { should validate_presence_of(:username) }
    it { should validate_uniqueness_of(:username).case_insensitive }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
  end

  describe "Associations" do
    it { should have_many(:created_servers).class_name('Server').with_foreign_key('creator_id') }
    it { should have_many(:memberships) }
    it { should have_many(:joined_servers).through(:memberships).source(:server) }
    it { should have_many(:messages) }
  end

  describe ".find_for_database_authentication" do
    let!(:user) { create(:user, username: 'testuser', email: 'test_user@example.com', password: 'password') }

    context "when login is provided as username" do
      it "finds the user by username" do
        found_user = User.find_for_database_authentication(login: 'testuser')
        expect(found_user).to eq(user)
      end
    end

    context "when login is provided as email" do
      it "finds the user by email" do
        found_user = User.find_for_database_authentication(login: 'test_user@example.com')
        expect(found_user).to eq(user)
      end
    end

    context "when no login is provided" do
      it "finds the user by conditions" do
        found_user = User.find_for_database_authentication(email: 'test_user@example.com')
        expect(found_user).to eq(user)
      end
    end
  end

  describe "Case-insensitive username uniqueness validation" do
    before do
      User.create!(username: 'TestUser', email: 'unique_user@example.com', password: 'password')
    end

    it "does not allow a username with a different case to be created" do
      duplicate_user = User.new(username: 'testuser', email: 'another@example.com', password: 'password')
      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:username]).to include("has already been taken")
    end

    it "allows a username with a completely different value to be created" do
      valid_user = User.new(username: 'AnotherUser', email: 'different@example.com', password: 'password')
      expect(valid_user).to be_valid
    end
  end

  describe "#online?" do
    let(:user) { create(:user) }

    context "when the user is online" do
      before do
        Rails.cache.write("user_#{user.id}_online", true, raw: true)
      end

      it "returns true" do
        expect(user.online?).to be true
      end
    end

    context "when the user is offline" do
      before do
        Rails.cache.write("user_#{user.id}_online", false, raw: true)
      end

      it "returns false" do
        expect(user.online?).to be false
      end
    end

    context "when there is no cache entry for the user" do
      before do
        Rails.cache.delete("user_#{user.id}_online")
      end

      it "returns false" do
        expect(user.online?).to be false
      end
    end
  end

  describe '#reassign_creator_roles' do
    let!(:user) { create(:user, username: 'creator_user', email: 'creator@example.com') }
    let!(:new_user) { create(:user, username: 'new_user', email: 'new_user@example.com') }
    let!(:server) do
      Server.create!(name: "Chat Room for Test Game", creator_id: user.id).tap do |server|
        server.update!(
          original_creator_id: user.id,
          original_creator_username: user.username,
          original_creator_email: user.email
        )
      end
    end
    let!(:game) do
      Game.create!(name: "Test Game", creator_id: user.id, server_id: server.id).tap do |game|
        server.update!(game_id: game.id)
      end
    end

    context 'when a new user exists' do
      it 'reassigns servers to a new user' do
        user.send(:reassign_creator_roles)
        expect(server.reload.creator_id).to eq(new_user.id)
      end

      it 'reassigns games to a new user' do
        user.send(:reassign_creator_roles)
        expect(game.reload.creator_id).to eq(new_user.id)
      end
    end

    context 'when no new user exists' do
      before do
        # Simulate no available user by stubbing the User query
        allow(User).to receive(:where).with(any_args).and_return(User.none)
      end

      it 'reassigns servers to the original creator if they exist' do
        user.send(:reassign_creator_roles)

        expect(server.reload.creator_id).to eq(user.id)
        expect(server.reload.original_creator_username).to eq(user.username)
        expect(server.reload.original_creator_email).to eq(user.email)
      end

      it 'sets creator_id to NULL if no valid user exists for a game' do
        server.update!(original_creator_id: nil, original_creator_username: nil, original_creator_email: nil)

        user.send(:reassign_creator_roles)

        expect(server.reload.creator_id).to be_nil
      end
    end
  end

  describe ".from_omniauth" do
    let(:auth_hash) do
      OmniAuth::AuthHash.new({
                               provider: 'google_oauth2',
                               uid: '1234567890',
                               info: {
                                 email: 'testuser@example.com'
                               }
                             })
    end

    context "when the user is new" do
      it "creates a new user with the correct attributes" do
        user = User.from_omniauth(auth_hash)

        expect(user).to be_persisted
        expect(user.email).to eq('testuser@example.com')
        expect(user.provider).to eq('google_oauth2')
        expect(user.uid).to eq('1234567890')
        expect(user.username).to eq('testuser')
      end
    end

    context "when the user already exists" do
      let!(:existing_user) { User.create!(email: 'testuser@example.com', provider: 'google_oauth2', uid: '1234567890', password: 'password', username: 'testuser') }

      it "does not create a new user and returns the existing user" do
        user = User.from_omniauth(auth_hash)

        expect(user).to eq(existing_user)
        expect(User.count).to eq(1)
      end
    end

    context "when the auth hash is missing required fields" do
      let(:invalid_auth_hash) do
        OmniAuth::AuthHash.new({
                                 provider: 'google_oauth2',
                                 uid: nil,
                                 info: {
                                   email: nil
                                 }
                               })
      end

      it "does not create a user when required fields are missing" do
        expect {
          User.from_omniauth(invalid_auth_hash)
        }.not_to change(User, :count)
      end
    end
  end
end