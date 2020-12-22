# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::OncallRotations::PersistShiftsJob do
  let(:worker) { described_class.new }

  let_it_be(:rotation) { create(:incident_management_oncall_rotation, :with_participant) }
  let(:rotation_id) { rotation.id }

  before do
    stub_licensed_features(oncall_schedules: true)
  end

  describe '#perform' do
    subject(:perform) { worker.perform(rotation_id) }

    context 'unknown rotation' do
      let(:rotation_id) { non_existing_record_id }

      it { is_expected.to be_nil }

      it 'does not create shifts' do
        expect { perform }.not_to change { IncidentManagement::OncallShift.count }
      end
    end

    it 'creates shifts' do
      expect { perform }.to change { rotation.shifts.count }.by(1)
    end

    context 'shift already created' do
      let_it_be(:existing_shift) do
        create(:incident_management_oncall_shift, rotation: rotation, participant: rotation.participants.first)
      end

      it 'does not create shifts' do
        expect { perform }.not_to change { IncidentManagement::OncallShift.count }
      end
    end
  end
end
