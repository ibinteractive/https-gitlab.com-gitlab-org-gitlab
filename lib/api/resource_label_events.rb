# frozen_string_literal: true

module API
  class ResourceLabelEvents < Grape::API
    include PaginationParams
    helpers ::API::Helpers::NotesHelpers

    before { authenticate! }

    Helpers::ResourceLabelEventsHelpers.eventable_types.each do |eventable_type|
      parent_type = eventable_type.parent_class.to_s.underscore
      eventables_str = eventable_type.to_s.underscore.pluralize

      params do
        requires :id, type: String, desc: "The ID of a #{parent_type}"
      end
      resource parent_type.pluralize.to_sym, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc "Get a list of #{eventable_type.to_s.downcase} resource label events" do
          success Entities::ResourceLabelEvent
          detail 'This feature was introduced in 11.3'
        end
        params do
          requires :eventable_id, types: [Integer, String], desc: 'The ID of the eventable'
          use :pagination
        end

        get ":id/#{eventables_str}/:eventable_id/resource_label_events" do
          eventable = find_noteable(eventable_type, params[:eventable_id])

          opts = { page: params[:page], per_page: params[:per_page] }
          events = ResourceLabelEventFinder.new(current_user, eventable, opts).execute

          present paginate(events), with: Entities::ResourceLabelEvent
        end

        desc "Get a single #{eventable_type.to_s.downcase} resource label event" do
          success Entities::ResourceLabelEvent
          detail 'This feature was introduced in 11.3'
        end
        params do
          requires :event_id, type: String, desc: 'The ID of a resource label event'
          requires :eventable_id, types: [Integer, String], desc: 'The ID of the eventable'
        end
        get ":id/#{eventables_str}/:eventable_id/resource_label_events/:event_id" do
          eventable = find_noteable(eventable_type, params[:eventable_id])

          event = eventable.resource_label_events.find(params[:event_id])

          not_found!('ResourceLabelEvent') unless can?(current_user, :read_resource_label_event, event)

          present event, with: Entities::ResourceLabelEvent
        end
      end
    end
  end
end
