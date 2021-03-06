# frozen_string_literal: true

module EE
  module JobsHelper
    extend ::Gitlab::Utils::Override

    override :jobs_data
    def jobs_data
      super.merge({
        "subscriptions_more_minutes_url" => ::EE::SUBSCRIPTIONS_MORE_MINUTES_URL
      })
    end
  end
end

::JobsHelper.prepend_if_ee('::EE::JobsHelper')
