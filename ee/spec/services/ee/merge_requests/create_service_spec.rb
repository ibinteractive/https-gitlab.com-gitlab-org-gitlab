# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::CreateService do
  include ProjectForksHelper

  let(:project) { create(:project, :repository) }
  let(:service) { described_class.new(project, user, opts) }
  let(:opts) do
    {
      title: 'Awesome merge_request',
      description: 'please fix',
      source_branch: 'feature',
      target_branch: 'master',
      force_remove_source_branch: '1'
    }
  end

  before do
    allow(service).to receive(:execute_hooks)
  end

  describe '#execute' do
    let(:user) { create(:user) }

    before do
      project.add_maintainer(user)
    end

    it 'refreshes code owners for the merge request' do
      fake_refresh_service = instance_double(::MergeRequests::SyncCodeOwnerApprovalRules)

      expect(::MergeRequests::SyncCodeOwnerApprovalRules)
        .to receive(:new).with(kind_of(MergeRequest)).and_return(fake_refresh_service)
      expect(fake_refresh_service).to receive(:execute)

      service.execute
    end

    context 'report approvers' do
      let(:sha) { project.repository.commits(opts[:source_branch], limit: 1).first.id }
      let(:pipeline) { instance_double(Ci::Pipeline, id: 42, project_id: project.id, merge_request?: true) }

      it 'refreshes report approvers for the merge request' do
        expect_next_instance_of(::MergeRequests::SyncReportApproverApprovalRules) do |service|
          expect(service).to receive(:execute)
        end

        service.execute
      end

      it 'enqueues approval rule report syncing when pipeline exists' do
        expect_next_instance_of(MergeRequest) do |merge_request|
          allow(merge_request).to receive(:find_actual_head_pipeline).and_return(pipeline)
          allow(merge_request).to receive(:update_head_pipeline).and_return(true)
        end
        expect(::SyncSecurityReportsToReportApprovalRulesWorker)
          .to receive(:perform_async)

        service.execute
      end

      it 'wont enqueue approval rule report syncing without pipeline' do
        expect(::SyncSecurityReportsToReportApprovalRulesWorker)
          .not_to receive(:perform_async)

        service.execute
      end
    end

    it_behaves_like 'new issuable with scoped labels' do
      let(:parent) { project }
    end
  end

  describe '#execute with blocking merge requests', :clean_gitlab_redis_shared_state do
    let(:opts) { { title: 'Blocked MR', source_branch: 'feature', target_branch: 'master' } }
    let(:user) { project.owner }

    it 'delegates to MergeRequests::UpdateBlocksService' do
      expect(MergeRequests::UpdateBlocksService)
        .to receive(:extract_params!)
        .and_return(:extracted_params)

      expect_next_instance_of(MergeRequests::UpdateBlocksService) do |block_service|
        expect(block_service.merge_request.title).to eq('Blocked MR')
        expect(block_service.current_user).to eq(user)
        expect(block_service.params).to eq(:extracted_params)

        expect(block_service).to receive(:execute)
      end

      service.execute
    end
  end
end
