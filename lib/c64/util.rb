
module C64
  class Util

    attr_accessor :output, :indent
    attr_accessor :byte_opcode, :byte_format, :byte_delim, :bytes_per_line

    # Generate sine table
    def self.sine(params = {})
      samples = params[:samples] || 256
      start   = params[:start]   || 0.0
      length  = params[:length]  || 2.0
      ampl    = params[:ampl].to_f || 128.0
      base    = params[:base].to_f || ampl
      to_i    = params[:to_i]
      ampl = ampl - 0.001 # Avoid rounding anomaly at min/max
      to_i = true if to_i.nil?
      (0...samples).map do |n|
        theta = (start.to_f + (n.to_f/samples.to_f) * length.to_f) * ::Math::PI
        value = base + ampl * ::Math.sin(theta)
        to_i ? value.to_i : value
      end
    end

    # Write an array of bytes to file, with optional load address header
    def self.write_bytes(filename, bytes, address = nil)
      File.open(filename, 'wb') do |file|
        file.write [address].pack('S') unless address.nil?
        file.write bytes.pack('C*')
      end
    end

    # Dump an array of bytes as an assembly table
    def self.write_tables(filename, &block)
      File.open(filename, 'w') do |file|
        util = new
        util.output = file
        block.call(util)
      end
    end

    def initialize
      @output = $stdout
      @indent = "\t"
      @byte_opcode = '.byt'
      @byte_format = '$%02X'
      @byte_delim = ','
      @bytes_per_line = 16
    end

    # Dump an array of bytes as an assembly table
    def dump_bytes(label, bytes)
      output.puts "#{label}:"
      output.puts bytes.each_slice(bytes_per_line).map { |line|
        "#{indent}#{byte_opcode} " +
        line.map {|byte| byte_format % byte }.join(byte_delim)
      }.join "\n"
      output.print "\n"
    end

    # Dump an array of words as two assembly tables,
    # one with lower bytes and one with upper bytes
    def dump_words(label, words)
      lo, hi = (label =~ /^[A-Z]/ ? ['Lo', 'Hi'] : ['_lo', '_hi'])
      dump_bytes("#{label}#{lo}", words.map {|n| n % 256 })
      dump_bytes("#{label}#{hi}", words.map {|n| n / 256 })
    end

  end
end
