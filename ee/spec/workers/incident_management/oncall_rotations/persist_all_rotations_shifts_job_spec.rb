# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::OncallRotations::PersistAllRotationsShiftsJob do
  let(:worker) { described_class.new }

  let_it_be(:rotation) { create(:incident_management_oncall_rotation, :with_participant) }

end
