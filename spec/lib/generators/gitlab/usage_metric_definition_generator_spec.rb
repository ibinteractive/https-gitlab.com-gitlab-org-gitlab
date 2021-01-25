# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageMetricDefinitionGenerator, :rails, type: :generator do
  using RSpec::Parameterized::TableSyntax

  destination File.join(Rails.root, 'tmp', 'metrics')
  setup :prepare_destination
  teardown :prepare_destination

  context 'with invalid options' do
    where(:dir, :error) do
      %w(--unknown-option) | /dir option is required/
      %w(--dir= --ee)      | /dir option is required/
      %w(--dir=7w)         | /Invalid dir 7w, allowed options are counts_7d, 7d, counts_28d, 28d, counts_all, all, settings, license/
      %w(--dir=7w --ee)    | /Invalid dir 7w, allowed options are counts_7d, 7d, counts_28d, 28d, counts_all, all, settings, license/
      %w(--dir=none)       | /Invalid dir none, allowed options are counts_7d, 7d, counts_28d, 28d, counts_all, all, settings, license/
    end

    let(:args) { ['metric.foo.bar'] + dir }

    with_them do
      it 'raise an error' do
        expect { run_generator(args) }.to raise_error(RuntimeError, error)
      end
    end

    it 'returns missing required arguments when no arguments are provided' do
      output = capture(:stderr) { run_generator([]) }

      expect(output).to eq("No value provided for required arguments 'key_path'\n")
    end

    it 'returns missing required arguments when only class options are provided' do
      output = capture(:stderr) { run_generator(['--dir']) }

      expect(output).to eq("No value provided for required arguments 'key_path'\n")
    end
  end

  context 'with valid options' do
    where(:dir, :directory, :expected_time_frame) do
      '--dir=settings'    | 'settings'   | 'none'
      '--dir=license'     | 'license'    | 'none'
      '--dir=7d'          | 'counts_7d'  | '7d'
      '--dir=counts_7d'   | 'counts_7d'  | '7d'
      '--dir=28d'         | 'counts_28d' | '28d'
      '--dir=counts_28d'  | 'counts_28d' | '28d'
      '--dir=all'         | 'counts_all' | 'all'
    end

    let(:key_path) { args.first }
    let(:file_name) { key_path.split('.').last }
    let(:args) { ['metric.foo.bar', dir] }

    with_them do
      shared_examples 'correct metric definition' do |distribution, extra_args, parent_dir|
        let(:yml_content) do
          <<~YAML
            # See Usage Ping metrics dictionary docs https://docs.gitlab.com/ee/development/usage_ping/metrics_dictionary.html
            key_path: #{key_path}
            value_type:
            product_category:
            stage:
            status:
            milestone:
            introduced_by_url:
            group:
            time_frame: #{expected_time_frame}
            data_source:
            distribution: #{distribution}
            # tier: ['free', 'starter', 'premium', 'ultimate', 'bronze', 'silver', 'gold']
            tier:
          YAML
        end

        subject { run_generator(args + [extra_args]) }

        it 'generates as expected' do
          file_path = "#{parent_dir}config/metrics/#{directory}/#{file_name}.yml"
          expected_content = yml_content

          subject

          expect(destination_root).to have_structure {
            file(file_path) do
              contains(expected_content)
            end
          }
        end
      end

      context 'without --ee' do
        it_behaves_like 'correct metric definition', %w(ce), '', ''
        it_behaves_like 'correct metric definition', %w(ce ee), '--ee', 'ee/'
      end
    end
  end
end
