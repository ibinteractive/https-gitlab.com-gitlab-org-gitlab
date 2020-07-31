# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pagination::GitalyKeysetPager do
  let(:pager) { described_class.new(request_context, project) }

  let_it_be(:project) { create(:project, :repository) }

  let(:request_context) { double("request context") }
  let(:finder) { double("branch finder") }
  let(:custom_port) { 8080 }
  let(:incoming_api_projects_url) { "#{Gitlab.config.gitlab.url}:#{custom_port}/api/v4/projects" }

  before do
    stub_config_setting(port: custom_port)
  end

  describe '.paginate' do
    let(:base_query) { { per_page: 2 } }
    let(:query) { base_query }

    before do
      allow(request_context).to receive(:params).and_return(query)
      allow(request_context).to receive(:header)
    end

    shared_examples_for 'offset pagination' do
      let(:paginated_array) { double 'paginated array' }
      let(:branches) { [] }

      it 'uses offset pagination' do
        expect(finder).to receive(:execute).and_return(branches)
        expect(Kaminari).to receive(:paginate_array).with(branches).and_return(paginated_array)
        expect_next_instance_of(Gitlab::Pagination::OffsetPagination) do |offset_pagination|
          expect(offset_pagination).to receive(:paginate).with(paginated_array)
        end

        pager.paginate(finder)
      end
    end

    context 'with branch_list_keyset_pagination feature off' do
      before do
        stub_feature_flags(branch_list_keyset_pagination: false)
      end

      context 'without keyset pagination option' do
        it_behaves_like 'offset pagination'
      end

      context 'with keyset pagination option' do
        let(:query) { base_query.merge(pagination: 'keyset') }

        it_behaves_like 'offset pagination'
      end
    end

    context 'with branch_list_keyset_pagination feature on' do
      before do
        stub_feature_flags(branch_list_keyset_pagination: project)
      end

      context 'without keyset pagination option' do
        it_behaves_like 'offset pagination'
      end

      context 'with keyset pagination option' do
        let(:query) { base_query.merge(pagination: 'keyset') }
        let(:fake_request) { double(url: "#{incoming_api_projects_url}?#{query.to_query}") }

        before do
          allow(request_context).to receive(:request).and_return(fake_request)
          expect(finder).to receive(:execute).with(gitaly_pagination: true).and_return(branches)
        end

        context 'when next page could be available' do
          let(:branch1) { double 'branch', name: 'branch1' }
          let(:branch2) { double 'branch', name: 'branch2' }
          let(:branches) { [branch1, branch2] }

          let(:expected_next_page_link) { %Q(<#{incoming_api_projects_url}?#{query.merge(page_token: branch2.name).to_query}>; rel="next") }

          it 'uses keyset pagination and adds link headers' do
            expect(request_context).to receive(:header).with('Links', expected_next_page_link)
            expect(request_context).to receive(:header).with('Link', expected_next_page_link)

            pager.paginate(finder)
          end
        end

        context 'when the current page is the last page' do
          let(:branch1) { double 'branch', name: 'branch1' }
          let(:branches) { [branch1] }

          it 'uses keyset pagination without link headers' do
            expect(request_context).not_to receive(:header).with('Links', anything)
            expect(request_context).not_to receive(:header).with('Link', anything)

            pager.paginate(finder)
          end
        end
      end
    end
  end
end
