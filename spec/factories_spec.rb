RSpec.describe "FactoryBot Factories" do
  it "creates a valid item" do
    expect(create(:item)).to be_valid
  end
end