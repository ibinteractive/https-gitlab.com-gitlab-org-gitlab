# frozen_string_literal: true

require 'rails/generators'

module Gitlab
  class UsageMetricDefinitionGenerator < Rails::Generators::Base
    VALID_OPTIONS = {
      'counts_7d'  => { 'regexp' => %r{(counts_7d)|(7d)|(count_7d)},           'time_frame' => '7d' },
      'counts_28d' => { 'regexp' => %r{(counts_28d)|(28d)|(count_28d)},        'time_frame' => '28d' },
      'counts_all' => { 'regexp' => %r{(counts_all)|(all)|(al)},               'time_frame' => 'all' },
      'settings'   => { 'regexp' => %r{(settings)|(setting)|(seting)(settin)}, 'time_frame' => 'none' },
      'license'    => { 'regexp' => %r{(license)|(licence)|(licese)},          'time_frame' => 'none' }
    }.freeze

    source_root File.expand_path('../../../generator_templates/usage_metric_definition', __dir__)

    desc 'Generates a metric definition yml file'

    class_option :ee, type: :boolean, optional: true, default: false, desc: 'Indicates if metric is for ee'
    class_option :dir, type: :string, desc: "Indicates the metric location. It must be one of: #{VALID_OPTIONS.keys.map(&:inspect).join(', ')}"

    argument :key_path, type: :string, desc: 'Unique JSON key path for the metric'

    def create_metric_file
      validate!

      template "metric_definition.yml", file_path
    end

    def time_frame
      VALID_OPTIONS[directory]['time_frame']
    end

    def distribution
      value = ['ce']
      value << 'ee' if ee?
      value
    end

    private

    def file_path
      path = File.join('config', 'metrics', directory, "#{file_name}.yml")
      path = File.join('ee', path) if ee?
      path
    end

    def validate!
      raise "--dir option is required" unless input_dir.present?
      raise "Invalid dir #{input_dir}, allowed options are #{VALID_OPTIONS.keys.join(', ')}" unless directory.present?
    end

    def ee?
      options[:ee]
    end

    def input_dir
      options[:dir]
    end

    def file_name
      key_path.split('.').last
    end

    def directory
      dir, _ = VALID_OPTIONS.find { |_, options| options['regexp'].match?(input_dir) }
      dir
    end
  end
end
