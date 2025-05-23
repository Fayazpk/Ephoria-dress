require 'rails_helper'

RSpec.describe "admin/subcategories/show", type: :view do
  before(:each) do
    assign(:admin_subcategory, Admin::Subcategory.create!(
                                 name: "Name",
                                 description: "MyText",
                                 category: nil
                               ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(//)
  end
end
