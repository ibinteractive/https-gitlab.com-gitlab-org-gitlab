# frozen_string_literal: true

require 'spec_helper'

describe Iterations::CreateService do
  shared_examples 'iterations create service' do
    let_it_be(:user) { create(:user) }

    before do
      parent.add_developer(user)
    end

    context 'iterations feature enabled' do
      before do
        stub_licensed_features(iterations: true)
      end

      describe '#execute' do
        let(:params) do
          {
              title: 'v2.1.9',
              description: 'Patch release to fix security issue',
              start_date: Time.current.to_s,
              due_date: 1.day.from_now.to_s
          }
        end

        let(:response) { described_class.new(parent, user, params).execute }
        let(:iteration) { response.payload[:iteration] }
        let(:errors) { response.payload[:errors] }

        context 'valid params' do
          it 'creates an iteration' do
            expect(response.success?).to be_truthy
            expect(iteration).to be_persisted
            expect(iteration.title).to eq('v2.1.9')
          end
        end

        context 'invalid params' do
          let(:params) do
            {
                description: 'Patch release to fix security issue'
            }
          end

          it 'does not create an iteration but returns errors' do
            expect(response.error?).to be_truthy
            expect(errors.messages).to match({ title: ["can't be blank"], due_date: ["can't be blank"], start_date: ["can't be blank"] })
          end
        end

        context 'no permissions' do
          before do
            parent.add_reporter(user)
          end

          it 'is not allowed' do
            expect(response.error?).to be_truthy
            expect(response.message).to eq('Operation not allowed')
          end
        end
      end
    end

    context 'iterations feature disabled' do
      before do
        stub_licensed_features(iterations: false)
      end

      describe '#execute' do
        let(:params) { { title: 'a' } }
        let(:response) { described_class.new(parent, user, params).execute }

        it 'is not allowed' do
          expect(response.error?).to be_truthy
          expect(response.message).to eq('Operation not allowed')
        end
      end
    end
  end

  context 'for projects' do
    let_it_be(:parent, refind: true) { create(:project) }

    it_behaves_like 'iterations create service'
  end

  context 'for groups' do
    let_it_be(:parent, refind: true) { create(:group) }

    it_behaves_like 'iterations create service'
  end
end
