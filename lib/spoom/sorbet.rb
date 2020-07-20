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
    extend T::Sig

    # Run `bundle install` so Sorbet is installed after.
    #
    # `work_dir` can be changed to run bundle in another directory than `.`.
    sig do
      params(
        work_dir: String,
        opts: T::Hash[Symbol, T.untyped]
      ).returns([String, String, T::Boolean])
    end
    def self.bundle_install(work_dir = '.', opts = {})
      Bundler.with_clean_env do
        opts[:chdir] = File.expand_path(work_dir)
        Open3.popen3("bundle", "install", opts) do |_, o, e, thread|
          status = T.cast(thread.value, Process::Status)
          out = o.read
          err = e.read
          raise BundleInstallError, "error during `bundle install` (#{err})" unless status.success?
          return out, err, status.success?
        end
      end
    end

    sig do
      params(
        work_dir: String,
        args: T::Array[String],
        opts: T::Hash[Symbol, T.untyped]
      ).returns(String)
    end
    def self.run_srb(work_dir = '.', args = [], opts = {})
      Bundler.with_clean_env do
        opts[:chdir] = File.expand_path(work_dir)
        Open3.popen2("bundle exec srb #{args.join(' ')}", opts) do |_, out, thread|
          status = T.cast(thread.value, Process::Status)
          raise SrbError, "error while running `srb` (#{err.read})" unless status.success?
          out.read
        end
      end
    end

    sig do
      params(
        work_dir: String,
        args: T::Array[String],
        opts: T::Hash[Symbol, T.untyped]
      ).returns([String, String])
    end
    def self.run_srb_and_capture_errors(work_dir = '.', args = [], opts = {})
      Bundler.with_clean_env do
        opts[:chdir] = File.expand_path(work_dir)
        Open3.popen3("bundle exec srb #{args.join(' ')}", opts) do |_, out, err, thread|
          status = T.cast(thread.value, Process::Status)
          raise SrbError, "error while running `srb` (#{err.read})" unless status.success?
          return out.read, err.read
        end
      end
    end

    sig do
      params(
        work_dir: String,
        args: T::Array[String],
      ).returns(String)
    end
    def self.run_srb_tc(work_dir = '.', args = [])
      run_srb(work_dir, ["tc", *args], opts)
    end

    sig do
      params(
        work_dir: String,
        args: T::Array[String],
        opts: T::Hash[Symbol, T.untyped]
      ).returns([String, String])
    end
    def self.run_srb_tc_and_capture_errors(work_dir = '.', args = [], opts = {})
      run_srb_and_capture_errors(work_dir, ["tc", *args], opts)
    end

    sig { params(work_dir: String).returns(Metrics) }
    def self.srb_metrics(work_dir = '.')
      run_srb_tc_and_capture_errors(work_dir, ["--metrics-file=metrics.tmp", "--error-white-list='0'"])
      json_string = File.read("#{work_dir}/metrics.tmp")
      metrics = Metrics.parse_string(json_string)
      File.delete("#{work_dir}/metrics.tmp")
      metrics
    end

    sig { params(work_dir: String).returns(String) }
    def self.srb_version(work_dir = '.')
      run_srb(work_dir, ["--version"]).split(" ")[2]
    end

    class BundleInstallError < Spoom::Error; end
    class SrbError < Spoom::Error; end
  end
end
