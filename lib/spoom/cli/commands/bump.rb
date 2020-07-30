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

        desc "bump", "change Sorbet sigils from one strictness to another when no errors"
        option :from, type: :string
        option :to, type: :string
        sig { params(directory: String).void }
        def bump(directory = ".")
          # Q: default values for from and to?
          from = options[:from] ? options[:from] : Sorbet::Sigils::STRICTNESS_FALSE
          to = options[:to] ? options[:to] : Sorbet::Sigils::STRICTNESS_TRUE

          # TODO: raise error in this case? risky otherwise? test without reporting errors
          raise(StandardError.new, "Invalid 'from' strictness") unless Sorbet::Sigils.valid_strictness?(from)
          raise(StandardError.new, "Invalid 'to' strictness") unless Sorbet::Sigils.valid_strictness?(to)

          files_to_bump = Sorbet::Sigils.files_with_sigil_strictness(directory, from)

          Sorbet::Sigils.change_sigil_in_files(files_to_bump, to)

          output, no_errors = Sorbet.srb_tc(File.expand_path(directory), capture_err: true)

          return [] if no_errors

          errors = Sorbet::Errors::Parser.parse_string(output)

          files_with_errors = errors.map(&:file).compact

          Sorbet::Sigils.change_sigil_in_files(files_with_errors, from)
        end

        no_commands do
        end
      end
    end
  end
end
