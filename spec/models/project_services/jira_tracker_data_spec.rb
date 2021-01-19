# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraTrackerData do
  let(:jira_tracker_data) { create(:jira_tracker_data) }

  describe 'associations' do
    it { is_expected.to belong_to(:service) }
  end

  describe 'deployment_type' do
    it { is_expected.to define_enum_for(:deployment_type).with_values([:unknown, :server, :cloud]).with_prefix(:deployment) }
  end

  describe 'proxy settings' do
    it { is_expected.to validate_length_of(:proxy_address).is_at_most(2048) }
    it { is_expected.to validate_length_of(:proxy_port).is_at_most(5) }
    it { is_expected.to validate_length_of(:proxy_username).is_at_most(255) }
    it { is_expected.to validate_length_of(:proxy_password).is_at_most(255) }

    shared_examples 'attribute under the text limit' do |attribute, value|
      before do
        jira_tracker_data.public_send("#{attribute}=", value)
      end

      it 'does not raise database level error' do
        expect { jira_tracker_data.save! }.not_to raise_error
      end
    end

    shared_examples 'attribute over the text limit' do |attribute, value|
      before do
        jira_tracker_data.public_send("#{attribute}=", value)
      end

      it 'raises a database level error' do
        expect { jira_tracker_data.save!(validate: false) }.to raise_error(ActiveRecord::StatementInvalid)
      end
    end

    it_behaves_like 'attribute under the text limit', :proxy_address, SecureRandom.alphanumeric(2048)
    it_behaves_like 'attribute over the text limit', :proxy_address, SecureRandom.alphanumeric(2049)
    it_behaves_like 'attribute under the text limit', :proxy_port, SecureRandom.alphanumeric(5)
    it_behaves_like 'attribute over the text limit', :proxy_port, SecureRandom.alphanumeric(6)
    it_behaves_like 'attribute under the text limit', :proxy_username, SecureRandom.alphanumeric(255)
    it_behaves_like 'attribute over the text limit', :proxy_username, SecureRandom.alphanumeric(258)
    it_behaves_like 'attribute under the text limit', :proxy_password, SecureRandom.alphanumeric(255)
    it_behaves_like 'attribute over the text limit', :proxy_password, SecureRandom.alphanumeric(258)
  end
end
