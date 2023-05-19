require "rails_helper"

RSpec.describe "Editing with an editor", js: true do
  let(:template) { file_fixture("article_published.txt").read }
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user, body_markdown: template) }
  let(:svg_image) { file_fixture("300x100.svg").read }

  before do
    allow(Settings::General).to receive(:main_social_image).and_return("https://dummyimage.com/800x600.jpg")
    allow(Settings::General).to receive(:logo_png).and_return("https://dummyimage.com/800x600.png")
    allow(Settings::General).to receive(:mascot_image_url).and_return("https://dummyimage.com/800x600.jpg")
    allow(Settings::General).to receive(:suggested_tags).and_return("coding, beginners")
    allow(Settings::General).to receive(:suggested_users).and_return("romagueramica")
    sign_in user
  end

  it "user previews their changes" do
    visit "/#{user.username}/#{article.slug}/edit"
    fill_in "article_body_markdown", with: template.gsub("Suspendisse", "Yooo")
    click_button("Preview")
    expect(page).to have_text("Yooo")
  end

  # 1st Try error in ./vendor/bundle/ruby/3.0.0/bundler/gems/appmap-ruby-15d5b8d057ec/lib/appmap/rspec.rb:248:
  # expected to find text "Yooo" in "DEV(local)\nDEV(local)\nCreate Post\nEdit\nPreview\n Upload image\nYou are currently using the basic markdown editor that uses Jekyll front matter. You can also use the rich+markdown editor you can find in UX settings.\nEditor Basics\nUse Markdown to write and format posts.\nCommonly used syntax\nEmbed rich content such as Tweets, YouTube videos, etc. Use the complete URL: {% embed https://... %}. See a list of supported embeds.\nIn addition to images for the post's content, you can also drag and drop a cover image.\nSaving ...". (However, it was found 1 time including non-visible text.)
  it "user updates their post", appmap: false do
    visit "/#{user.username}/#{article.slug}/edit"
    fill_in "article_body_markdown", with: template.gsub("Suspendisse", "Yooo")
    click_button("Save changes")
    expect(page).to have_text("Yooo")
  end

  it "user unpublishes their post" do
    visit "/#{user.username}/#{article.slug}/edit"
    fill_in("article_body_markdown", with: template.gsub("true", "false"), fill_options: { clear: :backspace })
    click_button("Save changes")
    expect(page).to have_text("Unpublished Post.")
  end

  context "when user edits too many articles" do
    let(:rate_limit_checker) { RateLimitChecker.new(user) }

    before do
      # avoid hitting new user rate limit check
      allow(user).to receive(:created_at).and_return(1.week.ago)
      allow(RateLimitChecker).to receive(:new).and_return(rate_limit_checker)
      allow(rate_limit_checker).to receive(:limit_by_action)
        .with(:article_update)
        .and_return(true)
    end

    it "displays a rate limit warning", :flaky, js: true do
      visit "/#{user.username}/#{article.slug}/edit"
      fill_in "article_body_markdown", with: template.gsub("Suspendisse", "Yooo")
      click_button "Save changes"
      expect(page).to have_text("Rate limit reached")
    end
  end
end
