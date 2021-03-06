shared_examples "nested documentable" do |documentable_factory_name, path, documentable_path_arguments, fill_resource_method_name, submit_button, documentable_success_notice|
  include ActionView::Helpers
  include DocumentsHelper
  include DocumentablesHelper

  let!(:administrator)          { create(:user) }
  let!(:user)                   { create(:user, :level_two) }
  let!(:arguments)              { {} }
  let!(:documentable)           { create(documentable_factory_name, author: user) }

  before do
    create(:administrator, user: administrator)

    documentable_path_arguments&.each do |argument_name, path_to_value|
        arguments.merge!("#{argument_name}": documentable.send(path_to_value))
    end
  end

  describe "at #{path}" do

    scenario "Should show new document link when max documents allowed limit is not reached" do
      login_as user
      visit send(path, arguments)

      expect(page).to have_selector "#new_document_link", visible: true
    end

    scenario "Should not show new document link when documentable max documents allowed limit is reached", :js do
      login_as user
      visit send(path, arguments)

      click_link "Add new document"
      sleep 1
      click_link "Add new document"
      sleep 1
      click_link "Add new document"

      expect(page).to have_selector "#new_document_link", visible: false
    end

    scenario "Should not show max documents warning when no documents added", :js do
      login_as user
      visit send(path, arguments)

      expect(page).to have_selector ".max-documents-notice", visible: false
    end

    scenario "Should show max documents warning when max documents allowed limit is reached", :js do
      login_as user
      visit send(path, arguments)

      click_link "Add new document"
      sleep 1
      click_link "Add new document"
      sleep 1
      click_link "Add new document"

      expect(page).to have_selector ".max-documents-notice", visible: true
    end

    scenario "Should hide max documents warning after any document removal", :js do
      login_as user
      visit send(path, arguments)

      click_link "Add new document"
      sleep 1
      click_link "Add new document"
      sleep 1
      click_link "Add new document"
      sleep 1
      within "#document_0" do
        find("a", text: "Remove document").click
      end
      sleep 1

      expect(page).to have_selector ".max-documents-notice", visible: false
    end

    scenario "Should update nested document file name after choosing a file", :js do
      login_as user
      visit send(path, arguments)

      attach_new_file(documentable_factory_name, 0, "spec/fixtures/files/empty.pdf")

      expect(page).to have_selector ".file-name", text: "empty.pdf"
    end

    scenario "Should update nested document file title with file name after choosing a file when no title defined", :js do
      login_as user
      visit send(path, arguments)

      attach_new_file(documentable_factory_name, 0, "spec/fixtures/files/empty.pdf")

      expect(find("##{documentable_factory_name}_documents_attributes_0_title").value).to eq "empty.pdf"
    end

    scenario "Should not update nested document file title with file name after choosing a file when title already defined", :js do
      login_as user
      visit send(path, arguments)

      click_link "Add new document"
      sleep 1
      fill_in "#{documentable_factory_name}[documents_attributes][0][title]", with: "Title"
      attach_file("#{documentable_factory_name}[documents_attributes][0][attachment]", "spec/fixtures/files/empty.pdf", make_visible: true)
      sleep 1

      expect(find("##{documentable_factory_name}_documents_attributes_0_title").value).to eq "Title"
    end

    scenario "Should update loading bar style after valid file upload", :js do
      login_as user
      visit send(path, arguments)

      attach_new_file(documentable_factory_name, 0, "spec/fixtures/files/empty.pdf")
      fill_in "#{documentable_factory_name}[documents_attributes][0][title]", with: "Title"

      expect(page).to have_selector ".loading-bar.complete"
    end

    scenario "Should update loading bar style after unvalid file upload", :js do
      login_as user
      visit send(path, arguments)

      attach_new_file(documentable_factory_name, 0, "spec/fixtures/files/logo_header.png")

      expect(page).to have_selector ".loading-bar.errors"
    end

    scenario "Should update document cached_attachment field after valid file upload", :js do
      login_as user
      visit send(path, arguments)

      attach_new_file(documentable_factory_name, 0, "spec/fixtures/files/empty.pdf")

      expect(find("input[name='#{documentable_factory_name}[documents_attributes][0][cached_attachment]']", visible: false).value).to include("empty.pdf")
    end

    scenario "Should not update document cached_attachment field after unvalid file upload", :js do
      login_as user
      visit send(path, arguments)

      attach_new_file(documentable_factory_name, 0, "spec/fixtures/files/logo_header.png")

      expect(find("input[name='#{documentable_factory_name}[documents_attributes][0][cached_attachment]']", visible: false).value).to eq ""
    end

    scenario "Should show document errors after unvalid file upload", :js do
      login_as user
      visit send(path, arguments)

      click_link "Add new document"
      sleep 1
      click_on submit_button

      within "#document_0" do
        expect(page).to have_content("can't be blank", count: 2)
      end
    end

    scenario "Should delete document after valid file upload and click on remove button", :js do
      login_as user
      visit send(path, arguments)

      attach_new_file(documentable_factory_name, 0, "spec/fixtures/files/empty.pdf")
      within "#document_0" do
        click_link "Remove document"
      end

      expect(page).not_to have_selector("#document_0")
    end

    scenario "Should delete document after valid file upload and click on remove button", :js do
      login_as user
      visit send(path, arguments)

      attach_new_file(documentable_factory_name, 0, "spec/fixtures/files/empty.pdf")
      within "#document_0" do
        click_link "Remove document"
      end

      expect(page).to have_content "Document was deleted successfully."
    end

    scenario "Should show successful notice when resource filled correctly without any nested documents", :js do
      login_as user
      visit send(path, arguments)
      send(fill_resource_method_name) if fill_resource_method_name

      click_on submit_button
      expect(page).to have_content documentable_success_notice
    end

    scenario "Should show successful notice when resource filled correctly and after valid file uploads", :js do
      login_as user
      visit send(path, arguments)
      send(fill_resource_method_name) if fill_resource_method_name

      attach_new_file(documentable_factory_name, 0, "spec/fixtures/files/empty.pdf")

      click_on submit_button
      expect(page).to have_content documentable_success_notice
    end

    scenario "Should show new document after successful creation with one uploaded file", :js do
      login_as user
      visit send(path, arguments)
      send(fill_resource_method_name) if fill_resource_method_name

      attach_new_file(documentable_factory_name, 0, "spec/fixtures/files/empty.pdf")

      click_on submit_button
      redirected_to_resource_show_or_navigate_to

      expect(page).to have_content "Documents (1)"
    end

    scenario "Should show resource with new document after successful creation with maximum allowed uploaded files", :js do
      login_as user
      visit send(path, arguments)
      send(fill_resource_method_name) if fill_resource_method_name

      documentable.class.max_documents_allowed.times.each do |index|
        attach_new_file(documentable_factory_name, index, "spec/fixtures/files/empty.pdf")
      end

      click_on submit_button
      redirected_to_resource_show_or_navigate_to

      expect(page).to have_content "Documents (#{documentable.class.max_documents_allowed})"
    end

  end

end

def redirected_to_resource_show_or_navigate_to
  find("a", text: "Not now, go to my proposal")
  click_on "Not now, go to my proposal"
rescue
  return
end

def attach_new_file(documentable_factory_name, index, path)
  click_link "Add new document"
  sleep 1
  attach_file("#{documentable_factory_name}[documents_attributes][#{index}][attachment]", path, make_visible: true)
  sleep 1
end

def fill_new_valid_proposal
  fill_in :proposal_title, with: "Proposal title #{rand(9999)}"
  fill_in :proposal_summary, with: "Proposal summary"
  fill_in :proposal_question, with: "Proposal question?"
  check :proposal_terms_of_service
end

def fill_new_valid_budget_investment
  page.select documentable.heading.name_scoped_by_group, from: :budget_investment_heading_id
  fill_in :budget_investment_title, with: "Budget investment title"
  fill_in_ckeditor "budget_investment_description", with: "Budget investment description"
  check :budget_investment_terms_of_service
end

