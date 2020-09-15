# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerabilities_finding_with_remediation, parent: :vulnerabilities_finding do
    transient do
      summary { nil }
    end

    after(:build) do |finding, evaluator|
      if evaluator.summary
        raw_metadata = Gitlab::Json.parse(finding.raw_metadata)
        raw_metadata.delete('solution')
        raw_metadata['remediations'] = [
          {
            summary: evaluator.summary
          }
        ]
        finding.raw_metadata = raw_metadata.to_json
      end
    end
  end

  factory :vulnerabilities_finding, class: 'Vulnerabilities::Finding', aliases: [:vulnerabilities_occurrence] do
    name { 'Cipher with no integrity' }
    project
    project_fingerprint { generate(:project_fingerprint) }
    primary_identifier factory: :vulnerabilities_identifier
    location_fingerprint { '4e5b6966dd100170b4b1ad599c7058cce91b57b4' }
    report_type { :sast }
    severity { :high }
    confidence { :medium }
    scanner factory: :vulnerabilities_scanner
    metadata_version { 'sast:1.0' }
    raw_metadata do
      {
        description: 'The cipher does not provide data integrity update 1',
        message: 'The cipher does not provide data integrity',
        cve: '818bf5dacb291e15d9e6dc3c5ac32178:CIPHER',
        solution: 'GCM mode introduces an HMAC into the resulting encrypted data, providing integrity of the result.',
        location: {
          file: 'maven/src/main/java/com/gitlab/security_products/tests/App.java',
          start_line: 29,
          end_line: 29,
          class: 'com.gitlab.security_products.tests.App',
          method: 'insecureCypher'
        },
        links: [
          {
            name: 'Cipher does not check for integrity first?',
            url: 'https://crypto.stackexchange.com/questions/31428/pbewithmd5anddes-cipher-does-not-check-for-integrity-first'
          }
        ],
        evidence: {
          summary: 'Credit card detected',
          request: {
            headers: [{ name: 'Accept', value: '*/*' }],
            method: 'GET',
            url: 'http://goat:8080/WebGoat/logout'
          },
          response: {
            headers: [{ name: 'Content-Length', value: '0' }],
            reason_phrase: 'OK',
            status_code: 200
          }
        }
      }.to_json
    end

    trait :detected do
      after(:create) do |finding|
        create(:vulnerability, :detected, project: finding.project, findings: [finding])
      end
    end

    trait :confirmed do
      after(:create) do |finding|
        create(:vulnerability, :confirmed, project: finding.project, findings: [finding])
      end
    end

    trait :resolved do
      after(:create) do |finding|
        create(:vulnerability, :resolved, project: finding.project, findings: [finding])
      end
    end

    trait :dismissed do
      after(:create) do |finding|
        create(:vulnerability, :dismissed, project: finding.project, findings: [finding])
        create(:vulnerability_feedback,
               :dismissal,
               project: finding.project,
               project_fingerprint: finding.project_fingerprint)
      end
    end

    trait :with_issue_feedback do
      after(:create) do |finding|
        create(:vulnerability_feedback,
               :issue,
               project: finding.project,
               project_fingerprint: finding.project_fingerprint)
      end
    end

    trait :with_remediation do
      after(:build) do |finding|
        raw_metadata = Gitlab::Json.parse(finding.raw_metadata)
        raw_metadata.delete(:solution)
        raw_metadata[:remediations] = [
          {
            summary: 'Use GCM mode which includes HMAC in the resulting encrypted data, providing integrity of the result.'
          }
        ]
        finding.raw_metadata = raw_metadata.to_json
      end
    end

    trait :identifier do
      after(:build) do |finding|
        identifier = build(
          :vulnerabilities_identifier,
          fingerprint: SecureRandom.hex(20),
          project: finding.project
        )

        finding.identifiers = [identifier]
      end
    end

    ::Vulnerabilities::Finding::REPORT_TYPES.keys.each do |security_report_type|
      trait security_report_type do
        report_type { security_report_type }
      end
    end
  end
end
