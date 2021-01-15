# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageMetricDefinitionGenerator, :rails, type: :generator do
  using RSpec::Parameterized::TableSyntax

  destination File.join(Rails.root, 'tmp', 'metrics')
  setup :prepare_destination
  teardown :prepare_destination

  context 'with invalid options' do
    where(:args, :error) do
      %w(metric.foo.bar --unknown-option) | /dir option is required/
      %w(metric.foo.bar --dir= --ee)      | /dir option is required/
      %w(metric.foo.bar --dir=7w)         | /Invalid dir 7w, allowed options are counts_7d, counts_28d, counts_all, settings, license/
      %w(metric.foo.bar --dir=7w --ee)    | /Invalid dir 7w, allowed options are counts_7d, counts_28d, counts_all, settings, license/
    end

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
    where(:args, :directory, :expected_time_frame) do
      %w(metric.foo.bar --dir=settings)   | 'settings'   | 'none'
      %w(metric.foo.bar --dir=license)    | 'license'    | 'none'
      %w(metric.foo.bar --dir=7d)         | 'counts_7d'  | '7d'
      %w(metric.foo.bar --dir=counts_7d)  | 'counts_7d'  | '7d'
      %w(metric.foo.bar --dir=28d)        | 'counts_28d' | '28d'
      %w(metric.foo.bar --dir=counts_28d) | 'counts_28d' | '28d'
      %w(metric.foo.bar --dir=all)        | 'counts_all' | 'all'
      %w(metric.foo.bar --dir=al)         | 'counts_all' | 'all'
    end

    let(:key_path) { args.first }
    let(:file_name) { key_path.split('.').last }

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
