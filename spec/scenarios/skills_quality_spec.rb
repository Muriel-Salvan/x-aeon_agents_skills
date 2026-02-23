require 'x-aeon_agents_skills/gen_helpers'

RSpec.describe 'Generated skills quality' do

  COMPLIANCE_SCORE_THRESHOLD = 90
  QUALITY_SCORE_THRESHOLDS = {
    Structure: 90,
    Clarity: 90,
    Specificity: 90,
    Advanced: 90,
    'Average score': 90
  }

  Dir.glob('skills/*').each do |skill_path|

    context "validating skill #{skill_path}" do

      it "has a compliance score of at least #{COMPLIANCE_SCORE_THRESHOLD}%" do
        check_output = without_cli_colors { `skillkit skillmd check #{skill_path} --verbose` }
        score = Integer(check_output.match(/Score: (\d+)\/100$/)[1])
        expect(score).to be >= COMPLIANCE_SCORE_THRESHOLD, "Compliance score of #{skill_path} is too low (#{score}/100):\n#{check_output}"
      end

      it 'has good quality scores' do
        skipped_quality_checks = ((XAeonAgentsSkills::GenHelpers.skill_config(File.basename(skill_path)) || {})['skip_quality_checks'] || '').split(',').map(&:strip)
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
