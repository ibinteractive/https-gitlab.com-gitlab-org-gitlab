# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'a tracked vs code unique action' do |event|
  before do
    stub_application_setting(usage_ping_enabled: true)
  end

  def count_unique(date_from:, date_to:)
    Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: action, start_date: date_from, end_date: date_to)
  end

  specify do
    aggregate_failures do
      expect(track_action(user: user1)).to be_truthy
      expect(track_action(user: user1)).to be_truthy
      expect(track_action(user: user2)).to be_truthy

      expect(count_unique(date_from: time - 1.week, date_to: time + 1.week)).to eq(2)
    end
  end

  it 'does not track edit actions if user is not present' do
    expect(track_action(user: nil)).to be_nil
  end
end

RSpec.describe Gitlab::UsageDataCounters::VSCodeExtensionActivityUniqueCounter, :clean_gitlab_redis_shared_state do
  let(:user1) { build(:user, id: 1) }
  let(:user2) { build(:user, id: 2) }
  let(:time) { Time.current }

  context 'when tracking a vs code api request' do
    it_behaves_like 'a tracked vs code unique action' do
      let(:action) { described_class::VS_CODE_API_REQUEST_ACTION }

      def track_action(params)
        described_class.track_vs_code_api_request(**params)
      end
    end
  end
end
