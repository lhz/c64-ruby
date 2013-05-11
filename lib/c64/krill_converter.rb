#!/usr/bin/env ruby

module C64
  class KrillConverter

    attr_writer :margin

    def self.process(original, compressed, target, type, margin = nil)
      converter = new(type)
      converter.margin = Integer(margin) if margin
      converter.read_original_file original
      converter.read_compressed_file compressed
      converter.convert_compressed
      converter.write_target target
    end

    def initialize(type)
      @type = type.to_sym
    end

    def margin
      @margin || (@type == :dnx ? 1 : 3)
    end

    def read_original_file(filename)
      @original_size = File.size(filename)
      @original_addr = File.open(filename, 'rb') {|f| f.read(2) }.unpack('S')[0]
    end

    def read_compressed_file(filename)
      @compressed_data = "\0\0"
      content = File.open(filename, 'rb') {|f| f.read }
      case @type
      when :bb, :byteboozer
        @compressed_data << content[2..-1]
      when :dnx, :doynax, :doynamite
        @compressed_data << [@original_addr].pack('S') << content
      end
      @compressed_size = @compressed_data.length
    end

    def convert_compressed
      @compressed_addr = @original_addr + @original_size + margin - @compressed_size
      @compressed_data[0..1] = [@compressed_addr].pack('S')
    end

    def write_target(filename)
      File.open(filename, 'wb') {|f| f.write @compressed_data }
    end

  end
end

if __FILE__ == $0
  original, compressed, target, type, margin = ARGV
  if original && compressed && target && type
    C64::KrillConverter.process(original, compressed, target, type, margin)
  else
    warn "Usage: #{$0} <original> <compressed> <target> <type> [margin]"
  end
end
