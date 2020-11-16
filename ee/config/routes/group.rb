# frozen_string_literal: true

constraints(::Constraints::GroupUrlConstrainer.new) do
  scope(path: 'groups/*group_id/-',
        module: :groups,
        as: :group,
        constraints: { group_id: Gitlab::PathRegex.full_namespace_route_regex }) do
    draw :wiki

    resources :group_members, only: [], concerns: :access_requestable do
      patch :override, on: :member
    end

    get '/analytics', to: redirect('groups/%{group_id}/-/contribution_analytics')
    resource :contribution_analytics, only: [:show]

    namespace :analytics do
      resource :productivity_analytics, only: :show
      resources :coverage_reports, only: :index
      resource :merge_request_analytics, only: :show
      resource :repository_analytics, only: :show
      resource :cycle_analytics, only: :show, path: 'value_stream_analytics'
      scope module: :cycle_analytics, as: 'cycle_analytics', path: 'value_stream_analytics' do
        resources :stages, only: [:index, :create, :update, :destroy] do
          member do
            get :duration_chart
            get :median
            get :records
          end
        end
        resources :value_streams, only: [:index, :create, :destroy] do
          resources :stages, only: [:index, :create, :update, :destroy] do
            member do
              get :duration_chart
              get :median
              get :records
            end
          end
        end
        resource :summary, controller: :summary, only: :show
        get '/time_summary' => 'summary#time_summary'
      end
      get '/cycle_analytics', to: redirect('-/analytics/value_stream_analytics')

      scope :type_of_work do
        resource :tasks_by_type, controller: :tasks_by_type, only: :show do
          get :top_labels
        end
      end
    end

    resource :ldap, only: [] do
      member do
        put :sync
      end
    end

    resource :ldap_settings, only: [:update]

    resource :issues_analytics, only: [:show]

    resource :insights, only: [:show], trailing_slash: true do
      collection do
        post :query
        get :embedded
      end
    end

    resource :notification_setting, only: [:update]

    resources :ldap_group_links, only: [:index, :create, :destroy]
    resources :saml_group_links, only: [:index, :create, :destroy]
    resources :audit_events, only: [:index]
    resources :usage_quotas, only: [:index]

    resources :hooks, only: [:index, :create, :edit, :update, :destroy], constraints: { id: /\d+/ } do
      member do
        post :test
      end
    end

    resources :autocomplete_sources, only: [] do
      collection do
        get 'members'
        get 'issues'
        get 'merge_requests'
        get 'labels'
        get 'epics'
        get 'commands'
        get 'milestones'
      end
    end

    resources :billings, only: [:index]
    resources :epics, concerns: :awardable, constraints: { id: /\d+/ } do
      member do
        get '/descriptions/:version_id/diff', action: :description_diff, as: :description_diff
        delete '/descriptions/:version_id', action: :delete_description_version, as: :delete_description_version
        get :discussions, format: :json
        get :realtime_changes
        post :toggle_subscription
      end

      resources :epic_issues, only: [:index, :create, :destroy, :update], as: 'issues', path: 'issues'
      resources :epic_links, only: [:index, :create, :destroy, :update], as: 'links', path: 'links'

      scope module: :epics do
        resources :notes, only: [:index, :create, :destroy, :update], concerns: :awardable, constraints: { id: /\d+/ }
      end

      collection do
        post :bulk_update
      end
    end

    resources :iterations, only: [:index, :new, :edit, :show], constraints: { id: /\d+/ }

    resources :issues, only: [] do
      collection do
        post :bulk_update
      end
    end

    resources :merge_requests, only: [] do
      collection do
        post :bulk_update
      end
    end

    resources :todos, only: [:create]
    resources :boards, only: [:create, :update, :destroy] do
      collection do
        get :recent
      end
    end

    namespace :security do
      resource :dashboard, only: [:show], controller: :dashboard
      resources :vulnerabilities, only: [:index]
      resource :compliance_dashboard, only: [:show]
      resource :discover, only: [:show], controller: :discover
      resources :credentials, only: [:index, :destroy]
      resources :merge_commit_reports, only: [:index], constraints: { format: :csv }
    end

    resource :push_rules, only: [:edit, :update]

    resource :saml_providers, path: 'saml', only: [:show, :create, :update] do
      callback_methods = Rails.env.test? ? [:get, :post] : [:post]
      match :callback, to: 'omniauth_callbacks#group_saml', via: callback_methods
      get :sso, to: 'sso#saml'
      delete :unlink, to: 'sso#unlink'
    end

    resource :scim_oauth, only: [:show, :create], controller: :scim_oauth

    get :sign_up, to: 'sso#sign_up_form'
    post :sign_up, to: 'sso#sign_up'
    post :authorize_managed_account, to: 'sso#authorize_managed_account'

    resource :roadmap, only: [:show], controller: 'roadmap'

    post '/restore' => '/groups#restore', as: :restore
  end
end
