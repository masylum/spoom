# typed: true
# frozen_string_literal: true

require "spoom/sorbet/config"
require "spoom/sorbet/errors"
require "spoom/sorbet/lsp"
require "spoom/sorbet/metrics"

require "open3"

module Spoom
  # All Sorbet-related services.
  module Sorbet
    # Run `bundle install` so Sorbet is installed after.
    #
    # `work_dir` can be changed to run bundle in another directory than `.`.
    def self.bundle_install(work_dir = '.', opts = {})
      Bundler.with_clean_env do
        opts[:chdir] = File.expand_path(work_dir)
        Open3.popen3("bundle", "install", "--quiet", opts) do |_, o, e, thread|
          status = T.cast(thread.value, Process::Status)
          out = o.read
          err = e.read
          raise BundleInstallError.new("error during `bundle install`", out, err) unless status.success?
          return out, err, status
        end
      end
    end

    class BundleInstallError < Spoom::Error
      attr_reader :out, :err

      def initialize(message, out, err)
        super(message)
        @out = out
        @err = err
      end
    end

    def self.run_srb_tc(work_dir = '.', args = [], opts = {})
      Bundler.with_clean_env do
        opts[:chdir] = File.expand_path(work_dir)
        Open3.popen2("bundle exec srb tc #{args.join(' ')}", opts) do |_, out, thread|
          return out.read, thread.value
        end
      end
    end

    def self.run_srb_tc_and_capture_errors(work_dir = '.', args = [], opts = {})
      Bundler.with_clean_env do
        opts[:chdir] = File.expand_path(work_dir)
        Open3.popen2e("bundle exec srb tc #{args.join(' ')}", opts) do |_, out, thread|
          return out.read, thread.value
        end
      end
    end
  end
end
