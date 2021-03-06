# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['BoardList'] do
  it 'has specific fields' do
    expected_fields = %w[milestone max_issue_count max_issue_weight assignee]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
