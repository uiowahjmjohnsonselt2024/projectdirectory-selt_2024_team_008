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
end