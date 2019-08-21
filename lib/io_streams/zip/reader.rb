module IOStreams
  module Zip
    class Reader
      # Read from a zip file or stream, decompressing the contents as it is read
      # The input stream from the first file found in the zip file is passed
      # to the supplied block
      #
      # Example:
      #   IOStreams::Zip::Reader.open('abc.zip') do |io_stream|
      #     # Read 256 bytes at a time
      #     while data = io_stream.read(256)
      #       puts data
      #     end
      #   end
      def self.open(file_name_or_io, &block)
        if !defined?(JRuby) && !defined?(::Zip)
          # MRI needs Ruby Zip, since it only has native support for GZip
          begin
            require 'zip'
          rescue LoadError => exc
            raise(LoadError, "Install gem 'rubyzip' to read and write Zip files: #{exc.message}")
          end
        end

        # File name supplied
        return read_file(file_name_or_io, &block) unless IOStreams.reader_stream?(file_name_or_io)

        # ZIP can only work against a file, not a stream, so create temp file.
        IOStreams::Path.temp_file_name('iostreams_zip') do |temp_file_name|
          IOStreams.copy(file_name_or_io, temp_file_name, target_options: {streams: []})
          read_file(temp_file_name, &block)
        end
      end

      if defined?(JRuby)
        # Java has built-in support for Zip files
        def self.read_file(file_name, &block)
          fin = Java::JavaIo::FileInputStream.new(file_name)
          zin = Java::JavaUtilZip::ZipInputStream.new(fin)
          zin.get_next_entry
          block.call(zin.to_io)
        ensure
          zin.close if zin
          fin.close if fin
        end

      else

        # Read from a zip file or stream, decompressing the contents as it is read
        # The input stream from the first file found in the zip file is passed
        # to the supplied block
        def self.read_file(file_name, &block)
          begin
            zin = ::Zip::InputStream.new(file_name)
            zin.get_next_entry
            block.call(zin)
          ensure
            begin
              zin.close if zin
            rescue IOError
              # Ignore file already closed errors since Zip::InputStream
              # does not have a #closed? method
            end
          end
        end

      end
    end
  end
end
