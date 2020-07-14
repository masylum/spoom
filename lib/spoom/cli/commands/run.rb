# typed: true
# frozen_string_literal: true

require_relative "base"

module Spoom
  module Cli
    module Commands
      class Run < Base
        default_task :tc

        desc "tc", "run srb tc"
        option :limit, type: :numeric, aliases: :l
        option :code, type: :numeric, aliases: :c
        option :sort, type: :string, default: nil, aliases: :s
        def tc
          in_sorbet_project!

          filter = options[:limit] || options[:code] || options[:sort]

          unless filter
            _, status = run_sorbet
            return status.success?
          end

          output, status = run_and_filter
          if status&.success?
            $stderr.print(output)
            return 0
          end

          errors = Spoom::Sorbet::Errors::Parser.parse_string(output)
          all_errors = errors.dup

          limit = options[:limit]
          sort = options[:sort]
          code = options[:code]
          colors = !options[:no_color]

          errors = sort == "code" ? errors.sort_by(&:code) : errors.sort
          errors = errors.select { |e| e.code == code } if code
          errors = errors.slice(0, limit) if limit

          errors.each do |e|
            code = colorize_code(e.code, colors)
            message = colorize_message(e.message, colors)
            $stderr.puts "#{code} - #{e.file}:#{e.line}: #{message}"
          end

          if all_errors.size == errors.size
            $stderr.puts "Errors: #{all_errors.size}"
          else
            $stderr.puts "Errors: #{errors.size} shown, #{all_errors.size} total"
          end

          1
        end

        no_commands do
          def run_sorbet
            Spoom::Sorbet.run_srb_tc
          end

          def run_and_filter
            Spoom::Sorbet.run_srb_tc_and_capture_errors
          end

          def colorize_code(code, colors = true)
            return code.to_s unless colors
            code.to_s.light_black
          end

          def colorize_message(message, colors = true)
            return message unless colors

            cyan = T.let(false, T::Boolean)
            word = StringIO.new
            message.chars.each do |c|
              if c == '`'
                cyan = !cyan
                next
              end
              word << (cyan ? c.cyan : c.red)
            end
            word.string
          end
        end
      end
    end
  end
end
