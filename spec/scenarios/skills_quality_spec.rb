require 'x-aeon_agents_skills/gen_helpers'

describe 'Generated skills quality' do

  COMPLIANCE_SCORE_THRESHOLD = 90
  QUALITY_SCORE_THRESHOLDS = {
    Structure: 90,
    Clarity: 90,
    Specificity: 90,
    Advanced: 90,
    'Average score': 90
  }
  SKILLS_TEST_DIR = 'skills.test'

  before(:context) do
    # Generate skills for tests
    FileUtils.rm_rf SKILLS_TEST_DIR
    expect(`bundle exec ruby bin/generate_skills --output-dir #{SKILLS_TEST_DIR}`).to include 'Skills generated successfully.'
  end

  Dir.glob('skills.src/*').map { |skill_path| File.basename(skill_path) }.each do |skill_name|
    skill_path = "#{SKILLS_TEST_DIR}/#{skill_name}"

    context "validating skill #{skill_name}" do

      it "has a compliance score of at least #{COMPLIANCE_SCORE_THRESHOLD}%" do
        check_output = without_cli_colors { `skillkit skillmd check #{skill_path} --verbose` }
        score = Integer(check_output.match(/Score: (\d+)\/100$/)[1])
        expect(score).to be >= COMPLIANCE_SCORE_THRESHOLD, "Compliance score of #{skill_path} is too low (#{score}/100):\n#{check_output}"
      end

      it 'has good quality scores' do
        skipped_quality_checks = ((XAeonAgentsSkills::GenHelpers.config(File.basename(skill_path)) || {})['skip_quality_checks'] || '').split(',').map(&:strip)
        check_output = without_cli_colors { `skillkit validate #{skill_path} --verbose` }
        QUALITY_SCORE_THRESHOLDS.each do |quality_property, quality_threshold|
          next if skipped_quality_checks.include?(quality_property.to_s)

          score = Integer(check_output.match(/#{Regexp.escape(quality_property)}: (\d+)\/100$/)[1])
          expect(score).to be >= quality_threshold, "Quality score (#{quality_property}) of #{skill_path} is too low (#{score}/100):\n#{check_output}"
        end
      end

    end

  end

end
