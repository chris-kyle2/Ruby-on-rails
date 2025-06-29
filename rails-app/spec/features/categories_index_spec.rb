require 'rails_helper'

RSpec.describe 'Categories Page Features', type: :feature do
  before(:each) do
    # Create the user first
    user = User.create!(
      name: 'mike',
      email: 'mike@gmail.com',
      password: 'mike123'
    )

    # Log in the user
    visit user_session_path
    fill_in 'Email', with: 'mike@gmail.com'
    fill_in 'Password', with: 'mike123'
    click_button 'Log in'

    # Create a category for the user
    category = user.categories.new(name: 'Safari')
    category.image.attach(
      io: File.open(Rails.root.join('spec', 'img', 'safari.png')),
      filename: 'safari.png',
      content_type: 'image/png'
    )
    category.save!

    # Navigate to the categories page
    visit categories_path
  end

  describe 'I can see' do
    it 'the title of the page' do
      expect(page).to have_content 'CATEGORIES'
    end

    it 'the name of the category' do
      expect(page).to have_content 'Safari'
    end

    it 'the total amount of transactions' do
      expect(page).to have_content '$0.0'
    end

    it 'a button to add a new category' do
      expect(page).to have_button 'New category'
    end

    it 'a link to create a new category' do
      expect(page).to have_link 'New category'
    end
  end
end
