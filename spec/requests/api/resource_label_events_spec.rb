# frozen_string_literal: true

require 'spec_helper'

describe API::ResourceLabelEvents do
  set(:user) { create(:user) }
  set(:project) { create(:project, :public, namespace: user.namespace) }
  set(:label) { create(:label, project: project) }

  before do
    project.add_developer(user)
  end

  shared_examples 'resource_label_events API' do |parent_type, eventable_type, id_name|
    describe "GET /#{parent_type}/:id/#{eventable_type}/:noteable_id/resource_label_events" do
      context "with local label reference" do
        let!(:event) { create_event(label) }

        it "returns an array of resource label events" do
          get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_label_events", user)

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.first['id']).to eq(event.id)
        end

        it "returns a 404 error when eventable id not found" do
          get api("/#{parent_type}/#{parent.id}/#{eventable_type}/12345/resource_label_events", user)

          expect(response).to have_gitlab_http_status(404)
        end

        it "returns 404 when not authorized" do
          parent.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
          private_user = create(:user)

          get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_label_events", private_user)

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context "with cross-project label reference" do
        let(:private_project) { create(:project, :private) }
        let(:project_label) { create(:label, project: private_project) }
        let!(:event) { create_event(project_label) }

        it "returns cross references accessible by user" do
          private_project.add_guest(user)

          get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_label_events", user)

          expect(json_response).to be_an Array
          expect(json_response.first['id']).to eq(event.id)
        end

        it "does not return cross references not accessible by user" do
          get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_label_events", user)

          expect(json_response).to be_an Array
          expect(json_response).to eq []
        end
      end
    end

    describe "GET /#{parent_type}/:id/#{eventable_type}/:noteable_id/resource_label_events/:event_id" do
      context "with local label reference" do
        let!(:event) { create_event(label) }

        it "returns a resource label event by id" do
          get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_label_events/#{event.id}", user)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['id']).to eq(event.id)
        end

        it "returns 404 when not authorized" do
          parent.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
          private_user = create(:user)

          get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_label_events/#{event.id}", private_user)

          expect(response).to have_gitlab_http_status(404)
        end

        it "returns a 404 error if resource label event not found" do
          get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_label_events/12345", user)

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context "with cross-project label reference" do
        let(:private_project) { create(:project, :private) }
        let(:project_label) { create(:label, project: private_project) }
        let!(:event) { create_event(project_label) }

        it "returns a 404 error if cross-reference project is not accessible" do
          get api("/#{parent_type}/#{parent.id}/#{eventable_type}/#{eventable[id_name]}/resource_label_events/#{event.id}", user)

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    def create_event(label)
      create(:resource_label_event, eventable.class.name.underscore => eventable, label: label)
    end
  end

  context 'when eventable is an Issue' do
    it_behaves_like 'resource_label_events API', 'projects', 'issues', 'iid' do
      let(:parent) { project }
      let(:eventable) { create(:issue, project: project, author: user) }
    end
  end

  context 'when eventable is an Epic' do
    let(:group) { create(:group, :public) }
    let(:epic) { create(:epic, group: group, author: user) }

    before do
      group.add_owner(user)
      stub_licensed_features(epics: true)
    end

    it_behaves_like 'resource_label_events API', 'groups', 'epics', 'id' do
      let(:parent) { group }
      let(:eventable) { epic }
      let!(:event) { create(:resource_label_event, epic: epic) }
    end
  end

  context 'when eventable is a Merge Request' do
    it_behaves_like 'resource_label_events API', 'projects', 'merge_requests', 'iid' do
      let(:parent) { project }
      let(:eventable) { create(:merge_request, source_project: project, target_project: project, author: user) }
    end
  end
end
