RSpec.describe 'Generated skills quality' do

  SCORE_THRESHOLD = 90

  Dir.glob('skills/*').each do |skill_path|

    context "validating skill #{skill_path}" do

      it "has a score of at least #{SCORE_THRESHOLD}%" do
        original_no_color = ENV['NO_COLOR']
        ENV['NO_COLOR'] = '1'
        begin
          check_output = `skillkit skillmd check #{skill_path} -v`
        ensure
          ENV['NO_COLOR'] = original_no_color
        end
        score = Integer(check_output.match(/Score: (\d+)\/100$/)[1])
        expect(score).to be >= SCORE_THRESHOLD, "Quality score of #{skill_path} is too low (#{score}/100):\n#{check_output}"
      end

    end

  end

end
