# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TimeboxesHelper do
  describe '#show_burndown_placeholder?' do
    let_it_be(:user) { build(:user) }

    subject { helper.show_burndown_placeholder?(milestone) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    describe('milestone does not support burndown charts') do
      let(:milestone) { double('Milestone', supports_milestone_charts?: false) }

      it { is_expected.to be false }
    end

    describe('user without permission') do
      let(:milestone) { double('Milestone', supports_milestone_charts?: true, resource_parent: 'board') }

      before do
        stub_can_admin_milestone(false)
      end

      it { is_expected.to be false }
    end

    describe('user with permission') do
      let(:milestone) { double('Milestone', supports_milestone_charts?: true, resource_parent: 'board') }

      before do
        stub_can_admin_milestone(true)
      end

      it { is_expected.to be true }
    end
  end

  describe '#legacy_milestone?' do
    subject { legacy_milestone?(milestone) }

    describe 'without any ResourceStateEvents' do
      let(:milestone) { double('Milestone', created_at: Date.current) }

      it { is_expected.to be_nil }
    end

    describe 'with ResourceStateEvent created before milestone' do
      let(:milestone) { double('Milestone', created_at: Date.current) }

      before do
        create_resource_state_event(Date.yesterday)
      end

      it { is_expected.to eq(false) }
    end

    describe 'with ResourceStateEvent created same day as milestone' do
      let(:milestone) { double('Milestone', created_at: Date.current) }

      before do
        create_resource_state_event
      end

      it { is_expected.to eq(false) }
    end

    describe 'with ResourceStateEvent created after milestone' do
      let(:milestone) { double('Milestone', created_at: Date.yesterday) }

      before do
        create_resource_state_event
      end

      it { is_expected.to eq(true) }
    end
  end

  def create_resource_state_event(created_at = Date.current)
    create(:resource_state_event, created_at: created_at)
  end

  def stub_can_admin_milestone(ability)
    allow(helper).to receive(:can?).with(user, :admin_milestone, milestone.resource_parent).and_return(ability)
  end
end
