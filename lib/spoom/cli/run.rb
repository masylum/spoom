# typed: true
# frozen_string_literal: true

module Spoom
  module Cli
    class Run < Thor
      include Helper

      default_task :tc

      desc "tc", "run srb tc"
      option :limit, type: :numeric, aliases: :l
      option :code, type: :numeric, aliases: :c
      option :sort, type: :string, aliases: :s
      def tc
        in_sorbet_project!

        path = exec_path
        limit = options[:limit]
        sort = options[:sort]
        code = options[:code]
        colors = options[:color]

        unless limit || code || sort
          return Spoom::Sorbet.srb_tc(path: path, capture_err: false).last
        end

        output, status = Spoom::Sorbet.srb_tc(path: path, capture_err: true)
        if status
          $stderr.print(output)
          return 0
        end

        errors = Spoom::Sorbet::Errors::Parser.parse_string(output)
        errors_count = errors.size

        errors = sort == "code" ? errors.sort_by { |e| [e.code, e.file, e.line, e.message] } : errors.sort
        errors = errors.select { |e| e.code == code } if code
        errors = T.must(errors.slice(0, limit)) if limit

        errors.each do |e|
          code = colorize_code(e.code, colors)
          message = colorize_message(e.message, colors)
          $stderr.puts "#{code} - #{e.file}:#{e.line}: #{message}"
        end

        if errors_count == errors.size
          $stderr.puts "Errors: #{errors_count}"
        else
          $stderr.puts "Errors: #{errors.size} shown, #{errors_count} total"
        end

        1
      end

      no_commands do
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
