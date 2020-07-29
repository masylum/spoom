# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    class SigilsTest < Minitest::Test
      def test_sigil_returns_the_sigil_from_a_strictness_string
        sigil = Sigils.sigil_string("false")
        assert_equal("# typed: false", sigil)
      end

      def test_sigil_empty_returns_sigil_without_strictness
        sigil = Sigils.sigil_string("")
        assert_equal("# typed: ", sigil)
      end

      def test_valid_strictness_returns_true
        ["ignore", "false", "true", "strict", "strong", "   strong   "].each do |strictness|
          content = <<~STR
            # typed: #{strictness}
            class A; end
          STR
          assert(Sigils.valid_strictness?(content))
        end
      end

      def test_valid_strictness_false
        ["", "FALSE", "foo"].each do |strictness|
          content = <<~STR
            # typed: #{strictness}
            class A; end
          STR
          refute(Sigils.valid_strictness?(content))
        end
      end

      def test_valid_strictness_none_return_false
        content = <<~STR
          class A; end
        STR

        refute(Sigils.valid_strictness?(content))
      end

      def test_strictness_return_expected
        ["ignore", "false", "true", "strict", "strong", "   strong   ", "foo", ""].each do |strictness|
          content = <<~STR
            # typed: #{strictness}
            class A; end
          STR

          strictness_found = Sigils.strictness(content)

          assert_equal(strictness.strip, strictness_found)
        end
      end

      def test_strictness_no_sigil_returns_nil
        content = <<~STR
          class A; end
        STR

        strictness = Sigils.strictness(content)
        assert_nil(strictness)
      end

      def test_strictness_first_valid_return
        content = <<~STR
          # typed: true
          # typed: strict
          class A; end
        STR

        strictness = Sigils.strictness(content)
        assert_equal("true", strictness)
      end

      def test_strictness_first_invalid_return
        content = <<~STR
          # typed: no
          # typed: strict
          class A; end
        STR

        strictness = Sigils.strictness(content)
        assert_equal("no", strictness)
      end

      def test_update_sigil_to_use_valid_strictness
        content = <<~STR
          # typed: ignore
          class A; end
        STR

        new_content = Sigils.update_sigil(content, "false")

        strictness = Sigils.strictness(new_content)

        assert_equal("false", strictness)
      end

      def test_update_sigil_to_use_invalid_strictness
        content = <<~STR
          # typed: ignore
          class A; end
        STR

        new_content = Sigils.update_sigil(content, "asdf")

        strictness = Sigils.strictness(new_content)

        assert_equal("asdf", strictness)
      end

      def test_update_sigil_first_of_multiple
        content = <<~STR
          # typed: strong
          # typed: ignore
          class A; end
        STR

        new_content = Sigils.update_sigil(content, "true")

        assert(/^# typed: ignore$/.match?(new_content))

        strictness = Sigils.strictness(new_content)

        assert_equal("true", strictness)
      end
    end
  end
end
