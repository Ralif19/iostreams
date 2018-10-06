require_relative 'test_helper'

class EncodeReaderTest < Minitest::Test
  describe IOStreams::Encode::Reader do
    let :bad_data do
      [
        "New M\xE9xico,NE".b,
        'good line',
        "New M\xE9xico,SF".b
      ].join("\n").encode('BINARY')
    end

    let :cleansed_data do
      bad_data.gsub("\xE9".b, '?')
    end

    describe '#read' do
      describe 'replacement' do
        it 'does not strip invalid characters' do
          input = StringIO.new(bad_data)
          IOStreams::Encode::Reader.open(input, encoding: 'UTF-8') do |io|
            assert_raises ::Encoding::UndefinedConversionError do
              ap io.read.encoding
            end
          end
        end

        it 'strips invalid characters' do
          input = StringIO.new(bad_data)
          data  =
            IOStreams::Encode::Reader.open(input, encoding: 'UTF-8', encode_replace: '?') do |io|
              io.read
            end
          assert_equal cleansed_data, data
        end
      end

      describe 'non_printable' do
        it 'strips non-printable characters' do
          input = StringIO.new(bad_data)
          data  =
            IOStreams::Encode::Reader.open(input, encoding: 'UTF-8', encode_cleaner: :non_printable, encode_replace: '?') do |io|
              io.read
            end
          assert_equal cleansed_data, data
        end
      end
    end
  end
end
