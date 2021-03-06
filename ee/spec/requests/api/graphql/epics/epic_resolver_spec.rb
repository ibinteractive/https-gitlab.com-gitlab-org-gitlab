# frozen_string_literal: true

require 'spec_helper'

describe 'getting epics information' do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
    group.add_maintainer(user)
    stub_licensed_features(epics: true)
  end

  describe 'query for epics which start with an iid' do
    let_it_be(:epic1) { create(:epic, group: group, iid: 11) }
    let_it_be(:epic2) { create(:epic, group: group, iid: 22) }
    let_it_be(:epic3) { create(:epic, group: group, iid: 2223) }
    let_it_be(:epic4) { create(:epic, group: group, iid: 29) }

    context 'when a valid iidStartsWith query is provided' do
      it 'returns the expected epics' do
        query_epics_which_start_with_iid('22')

        expect_epics_response(epic2, epic3)
      end
    end

    context 'when invalid iidStartsWith query is provided' do
      it 'fails with negative number' do
        query_epics_which_start_with_iid('-2')

        expect(graphql_errors).to include(a_hash_including('message' => 'Invalid `iidStartsWith` query'))
      end

      it 'fails with string' do
        query_epics_which_start_with_iid('foo')

        expect(graphql_errors).to include(a_hash_including('message' => 'Invalid `iidStartsWith` query'))
      end

      it 'fails if query contains line breaks' do
        query_epics_which_start_with_iid('2\nfoo')

        expect(graphql_errors).to include(a_hash_including('message' => 'Invalid `iidStartsWith` query'))
      end
    end

    def query_epics_which_start_with_iid(iid)
      post_graphql(epics_query(group, 'iidStartsWith', iid), current_user: user)
    end
  end

  describe 'query for epics by time frame' do
    let_it_be(:epic1) { create(:epic, group: group, state: :opened, start_date: "2019-08-13", end_date: "2019-08-20") }
    let_it_be(:epic2) { create(:epic, group: group, state: :closed, start_date: "2019-08-13", end_date: "2019-08-21") }
    let_it_be(:epic3) { create(:epic, group: group, state: :closed, start_date: "2019-08-22", end_date: "2019-08-26") }
    let_it_be(:epic4) { create(:epic, group: group, state: :closed, start_date: "2019-08-10", end_date: "2019-08-12") }

    context 'when start_date and end_date are present' do
      it 'returns epics within timeframe' do
        post_graphql(epics_query_by_hash(group, 'startDate' => '2019-08-13', 'endDate' => '2019-08-21'), current_user: user)

        expect_epics_response(epic1, epic2)
      end
    end

    context 'when only start_date is present' do
      it 'raises error' do
        post_graphql(epics_query(group, 'startDate', '2019-08-13'), current_user: user)

        expect(graphql_errors).to include(a_hash_including('message' => 'Both startDate and endDate must be present.'))
      end
    end

    context 'when only end_date is present' do
      it 'raises error' do
        post_graphql(epics_query(group, 'endDate', '2019-08-13'), current_user: user)

        expect(graphql_errors).to include(a_hash_including('message' => 'Both startDate and endDate must be present.'))
      end
    end
  end

  def epics_query(group, field, value)
    epics_query_by_hash(group, field => value)
  end

  def epics_query_by_hash(group, args)
    field_queries = args.map { |key, value| "#{key}:\"#{value}\"" }.join(',')

    <<~QUERY
        query {
          group(fullPath:"#{group.full_path}") {
            id,
            epics(#{field_queries}) {
              nodes {
                id
              }
            }
          }
        }
    QUERY
  end

  def expect_epics_response(*epics)
    actual_epics = graphql_data['group']['epics']['nodes'].map { |epic| epic['id'] }
    expected_epics = epics.map { |epic| epic.to_global_id.to_s }

    expect(actual_epics).to contain_exactly(*expected_epics)
    expect(graphql_errors).to be_nil
  end
end
