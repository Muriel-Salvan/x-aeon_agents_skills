# frozen_string_literal: true

require 'spec_helper'
require 'x-aeon_agents_skills_test/helpers'

RSpec.describe 'skills executable' do

  include XAeonAgentsSkillsTest::Helpers

  describe 'install command' do

    context 'with empty Skillfile' do
      it 'does not attempt to install any skills' do
        with_installable_skills do
          with_skills_spec('') do
            run_skills_install
            expect(@installed_skills).to eq []
          end
        end
      end
    end

    context 'with single skill' do
      it 'attempts to install the skill' do
        with_installable_skills('path-to/my-skill') do
          with_skills_spec('skill \'path-to/my-skill\'') do
            run_skills_install
            expect(@installed_skills).to eq ['path-to/my-skill']
          end
        end
      end
    end

    context 'with skills from repository context' do
      it 'prepends the repository name to skill references' do
        with_installable_skills('owner/repo/my-skill') do
          with_skills_spec(<<~SPEC) do
            from_skills 'owner/repo' do
              skill 'my-skill'
            end
          SPEC

            run_skills_install
            expect(@installed_skills).to eq ['owner/repo/my-skill']
          end
        end
      end
    end

  end

end
