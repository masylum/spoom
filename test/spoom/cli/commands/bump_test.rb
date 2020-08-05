# typed: false
# frozen_string_literal: true

require 'pathname'

require_relative "../cli_test_helper"

module Spoom
  module Cli
    module Commands
      class BumpTest < Minitest::Test
        include Spoom::Cli::TestHelper
        extend Spoom::Cli::TestHelper

        PROJECT = "project-bump"
        TEMPORARY_DIRECTORY = "#{TEST_PROJECTS_PATH}/#{PROJECT}/test-bump"

        before_all do
          install_sorbet(PROJECT)
        end

        # TODO: add directory to the config?
        # Q: is this the right place for setting the config?
        def setup
          use_sorbet_config(PROJECT, <<~CFG)
            .
          CFG
        end

        def teardown
          FileUtils.remove_dir(TEMPORARY_DIRECTORY, true)
        end

        def test_bump_files_one_error_no_bump_one_no_error_bump
          content1 = <<~STR
            # typed: false
            class A; end
          STR

          content2 = <<~STR
            # typed: false
            T.reveal_type(1)
          STR

          FileUtils.mkdir_p(TEMPORARY_DIRECTORY)

          File.write("#{TEMPORARY_DIRECTORY}/file1.rb", content1)
          File.write("#{TEMPORARY_DIRECTORY}/file2.rb", content2)

          Bump.new.bump("#{TEST_PROJECTS_PATH}/#{PROJECT}")

          strictness1 = Sorbet::Sigils.file_strictness("#{TEMPORARY_DIRECTORY}/file1.rb")
          strictness2 = Sorbet::Sigils.file_strictness("#{TEMPORARY_DIRECTORY}/file2.rb")

          assert_equal("true", strictness1)
          assert_equal("false", strictness2)
        end

        def test_bump_doesnt_change_sigils_outside_directory
          skip
          # use_sorbet_config(PROJECT, nil)

          content = <<~STR
            # typed: true
            T.reveal_type(1)
          STR

          File.write("./file.rb", content)

          Bump.new.bump("#{TEST_PROJECTS_PATH}/#{PROJECT}")

          strictness = Sorbet::Sigils.file_strictness("./file.rb")

          assert_equal("true", strictness)

          File.delete("./file.rb")
        end

        def test_bump_nondefault_from_to_complete
          skip
          from = "ignore"
          to = "strict"

          content = <<~STR
            # typed: #{from}
            class A; end
          STR

          FileUtils.mkdir_p(TEMPORARY_DIRECTORY)

          File.write("#{TEMPORARY_DIRECTORY}/file.rb", content)

          run_cli(TEMPORARY_DIRECTORY, "bump --from #{from} --to #{to}")
        end

        def test_bump_nondefault_from_to_revert
        end
      end
    end
  end
end
