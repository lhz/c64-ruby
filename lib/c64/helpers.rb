module C64
  module Helpers

    # Generate sine table
    def sine_table(samples: 256, start: 0.0, length: 2.0, ampl: 128, to_i: true, base: nil)
      ampl = ampl.to_f - 0.001 # Avoid rounding anomaly at min/max
      base = (base || ampl).to_f
      (0...samples).map do |n|
        theta = (start.to_f + (n.to_f/samples.to_f) * length.to_f) * ::Math::PI
        value = base + ampl * ::Math.sin(theta)
        to_i ? value.to_i : value
      end
    end

    # Write an array of bytes to file, with optional load address header
    def write_binary(file:, data:, address: nil)
      File.open(file, 'wb') do |f|
        f.write Array(address).pack('S') if address
        f.write Array(data.flatten).pack('C*')
      end
    end
  end
end
