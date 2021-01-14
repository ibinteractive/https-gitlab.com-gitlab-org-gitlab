# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::OncallRotations::PersistShiftsJob do
  let(:worker) { described_class.new }

  let_it_be(:rotation) { create(:incident_management_oncall_rotation, :with_participant, starts_at: 1.day.ago) }
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
      expect(rotation.shifts.first.starts_at).to be_within(1.second).of(rotation.starts_at)
    end

    context 'shift already created' do
      let_it_be(:existing_shift) do
        create(:incident_management_oncall_shift, rotation: rotation, participant: rotation.participants.first, starts_at: rotation.starts_at + 2.hours)
      end

      it 'does not create shifts' do
        expect { perform }.not_to change { IncidentManagement::OncallShift.count }
      end

      # Simulates a rotation changing from days to hours, which would
      # result in invalid data being backfilled.
      # This is avoided by using the latest shift start date
      # when creating the ReadService
      context 'rotation duration changed' do
        before do
          rotation.update!(length: 1, length_unit: 'hours')
        end

        it 'does not backfill create shifts' do
          expect { perform }.not_to change { IncidentManagement::OncallShift.count }
        end
      end
    end

    context 'error in generate' do
      before do
        allow(worker).to receive(:generate_shifts).with(rotation).and_return(
          double(success?: false, message: 'Error')
        )
      end

      it 'logs the error' do
        expect(Gitlab::AppLogger).to receive(:error).with('Could not generate shifts. Error: Error')

        perform
      end
    end
  end
end
