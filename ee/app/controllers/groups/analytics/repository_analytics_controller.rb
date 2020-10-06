# frozen_string_literal: true

class Groups::Analytics::RepositoryAnalyticsController < Groups::Analytics::ApplicationController
  layout 'group'

  before_action :load_group
  before_action :check_feature_flag
  before_action -> { check_feature_availability!(:group_repository_analytics) }
  before_action -> { authorize_view_by_action!(:read_group_repository_analytics) }
  before_action -> { push_frontend_feature_flag(:group_coverage_data_report, @group, default_enabled: false) }

  def show
    track_event(pageview_tracker_params)
  end

  private

  def pageview_tracker_params
    {
      label: 'group_id',
      value: @group.id
    }
  end

  def check_feature_flag
    render_404 unless @group.feature_available?(:group_coverage_reports)
  end
end
