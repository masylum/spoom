# typed: true
# frozen_string_literal: true

require 'pathname'

require_relative "../cli_test_helper"

module Spoom
  module Cli
    module Commands
      class BumpTest < Minitest::Test
        include Spoom::Cli::TestHelper
        extend Spoom::Cli::TestHelper

        TEMPORARY_DIRECTORY = "test-bump"

        def teardown
          FileUtils.remove_dir(TEMPORARY_DIRECTORY, true)
        end

        def test_bump_files_one_error_one_no_error_acceptance
          content1 = <<~STR
            # typed: false
            class A; end
          STR

          content2 = <<~STR
            # typed: false
            T.reveal_type(1.to_s)
          STR

          FileUtils.mkdir_p(TEMPORARY_DIRECTORY)

          File.write("#{TEMPORARY_DIRECTORY}/file1.rb", content1)
          File.write("#{TEMPORARY_DIRECTORY}/file2.rb", content2)

          Bump.new.bump(TEMPORARY_DIRECTORY)

          strictness1 = Spoom::Sorbet::Sigils.file_strictness("#{TEMPORARY_DIRECTORY}/file1.rb")
          strictness2 = Spoom::Sorbet::Sigils.file_strictness("#{TEMPORARY_DIRECTORY}/file2.rb")

          assert_equal("true", strictness1)
          assert_equal("false", strictness2)
        end
      end
    end
  end
end
