# typed: true
# frozen_string_literal: true

require 'find'
require 'open3'

require_relative 'base'

module Spoom
  module Cli
    module Commands
      class Bump < Base
        extend T::Sig

        default_task :bump

        desc "bump", "bump Sorbet sigils from `false` to `true` when no errors"
        sig { params(directory: String).void }
        def bump(directory = ".")
          files_to_bump = Spoom::Sorbet::Sigils.files_with_sigil_strictness(directory, "false")

          Spoom::Sorbet::Sigils.change_sigil_in_files(files_to_bump, "true")

          output, no_errors = Spoom::Sorbet.srb_tc(File.expand_path(directory), capture_err: true)

          return [] if no_errors

          errors = Spoom::Sorbet::Errors::Parser.parse_string(output)

          files_with_errors = errors.map(&:file).compact

          Spoom::Sorbet::Sigils.change_sigil_in_files(files_with_errors, "false")
        end

        no_commands do
        end
      end
    end
  end
end
