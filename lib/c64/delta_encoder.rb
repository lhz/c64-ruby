module C64
  class DeltaEncoder

    attr_reader :num_objects, :steps, :deltas, :delta_array, :delta_index, :script

    def initialize(num_objects, num_traits, options = {})
      @num_objects = num_objects
      @num_traits  = num_traits
      @ranges = options[:ranges] || [(-7..7)] * num_traits
      @modulo = options[:modulo]
      @steps  = Array.new(num_objects) { [] }
      @deltas = Hash.new { 0 }
    end

    def record_step(index, state)
      step = {s: state}
      if prev = @steps[index].last
        step[:d] = prev[:s].map.with_index do |value, i|
          delta_with_modulo value, state[i], @modulo[i]
        end
        register_delta step[:d]
      end
      # puts "RECORDED: [#{index}] #{step.inspect}"
      @steps[index] << step
    end

    def delta_with_modulo(from, to, modulo)
      delta = to - from
      if modulo && delta > modulo / 2
        delta -= modulo
      elsif modulo && delta < -modulo / 2
        delta += modulo
      end
      delta
    end

    def step_count
      @steps[0].size
    end

    def all_within_range?(deltas)
      deltas.map.with_index.all? {|d, i| @ranges[i].include? d }
    end

    def prune_deltas
      @deltas.delete_if {|k, v| !all_within_range?(k) }
    end

    def index_deltas
      @delta_array = @deltas.sort_by {|k, v| -v }.map(&:first)
      @delta_index = Hash[*(@delta_array.map.with_index.to_a.flatten(1))]
    end

    def compile(filename = 'scripts.bin', address = 0x8000)
      prune_deltas
      index_deltas

      puts "STEPS: #{step_count}"
      puts "DELTA: #{delta_array.size}"
      # puts "ARRAY: #{delta_array.inspect}"
      # puts "INDEX: #{delta_index.inspect}"

      scripts = num_objects.times.map do |i|
        compile_object i
      end
      # puts "SCRIPT SIZES: #{scripts.map(&:size).join(', ')}"

      addr_offset = 2 * (num_objects + @num_traits + 1)
      addresses = scripts.each_with_object([address + addr_offset]) do |scr, addr|
        addr << addr[-1] + scr.size
      end
      (@num_traits - 1).times do
        addresses << addresses[-1] + delta_array.size
      end

      out_header = addresses[0...num_objects].map {|a| a % 256 }
      out_header += addresses[0...num_objects].map {|a| a / 256 }
      out_header += addresses[num_objects..-1].pack('S*').bytes
      out_header += [steps.map(&:size).max].pack('S*').bytes

      out_script = scripts.flatten
      out_deltas = delta_array.transpose.flatten
      out_bytes  = out_header + out_script + out_deltas

      puts "SIZE: #{out_header.size} header, #{out_script.size} scripts, #{out_deltas.size} deltas, #{out_bytes.size} total"

      C64::Util.write_bytes filename, out_bytes, address
    end

    # compile_chunked('scripts', [0x5000..0x5FFF, 0x9000..0x9FFF, 0xF800..0xFFC0])

    class Bin
      attr_accessor :address, :free, :items
      def initialize(address, free)
        @address = address
        @free    = free
        @items   = []
      end
      def add(item)
        raise "No space remaining!" unless @free >= item[:size]
        @free -= item[:size]
        @items << item
        self
      end
      def dump
        puts "  Address: $%04X, Free: %d" % [address, free]
        items.each { |item| puts "    #{item.inspect}" }
      end
    end

    class BinSet
      attr_reader :bins
      def initialize(chunks)
        @bins = chunks.map { |c| Bin.new(c.first, c.size) }
      end
      def first
        bins.first
      end
      def first_free(size)
        bins.index {|b| b.free >= size} or
          raise "No bin found with #{size} free space remaining:\n#{dump}"
      end
      def add(item)
        index = first_free(item[:size])
        bins[index].add item
      end
      def dump
        puts "BinSet:"
        bins.each {|bin| bin.dump }
      end
    end

    def compile_chunked(basename = 'scripts', *chunks)
      prune_deltas
      index_deltas

      puts "STEPS: #{step_count}"
      puts "DELTA: #{delta_array.size}"

      scripts = num_objects.times.map do |i|
        compile_object i
      end

      header_size = 2 * (num_objects + @num_traits + 1)

      # Pack header, deltas and scripts into chunks
      bin_set = BinSet.new(chunks)
      bin_set.add :type => :header, :size => header_size
      @num_traits.times do |tn|
        bin_set.add :type => :delta, :index => tn, :size => delta_array.size
      end
      descending = scripts.sort_by {|s| -s.size}
      descending.each_with_index do |script, si|
        bin_set.add :type => :script, :index => si, :size => script.size
      end

      bin_set.dump

      addresses = bin_set.bins.map.with_index do |bin, index|
        address = bin.address
        bin.items.map do |item|
          old_address = address
          address += item[:size]
          old_address
        end
      end.flatten

      puts addresses.map {|a| "$%04X" % a}.join " "

      bin_set.bins.each_with_index do |bin, index|
        bytes = []
        bin.items.each do |item|
          case item[:type]
          when :header
            bytes += addresses[@num_traits+1..@num_traits+num_objects].map {|a| a % 256 }
            bytes += addresses[@num_traits+1..@num_traits+num_objects].map {|a| a / 256 }
            bytes += addresses[1..@num_traits].pack('S*').bytes
            bytes += [steps.map(&:size).max].pack('S*').bytes
          when :delta
            bytes += delta_array.transpose[item[:index]]
          when :script
            bytes += descending[item[:index]]
          end
        end
        C64::Util.write_bytes "#{basename}-#{index}.bin", bytes, bin.address
      end
    end

    def compile_object(index)
      script_start

      # Set initial state outside screen, then sleep until object visible
      frame = first_visible(steps[index]) or
        raise "Object ##{index} is never visible!"
      if frame > 0
        script_state [0, 0, 0]
        script_sleep frame - 1
      end

      # Set initial visible state
      script_state steps[index][frame][:s]
      frame += 1

      # Handle remaining steps
      while frame < steps[index].size
        deltas = steps[index][frame][:d]
        # No movement
        if deltas.all?(&:zero?)
          num_frames = steps[index][frame..-1].index {|s| s[:d].any?(&:nonzero?) }
          if num_frames
            script_sleep num_frames
            frame += num_frames
          else
            frame = steps[index].size
          end
        elsif delta_index.key?(deltas)
          script_delta delta_index[deltas]
          frame += 1
        else
          # puts "Warning: Not in delta index: #{deltas.inspect}"
          script_state steps[index][frame][:s]
          frame += 1
        end
      end

      script_end

      # script_annotate(index) if index == 0

      script
    end

    def script_annotate(index)
      puts "=== SCRIPT FOR OBJECT ##{index} === "
      pos = 0
      while pos < @script.size
        case byte = @script[pos]
        when 0xC0..0xFF
          x, y = @script[pos + 1, 2]
          x += 256 if byte % 2 > 0
          r = (byte & 0b00111110) >> 1
          puts "%02X %02X %02X  ; state x = #{x}, y = #{y}, r = #{r}" % @script[pos, 3]
          pos += 3
        when 0x81..0xBF
          puts "%02X        ; sleep #{byte & 0x3F} frames" % byte
          pos += 1
        when 0x80
          puts "%02X        ; end" % byte
          pos += 1
        else
          d = delta_array[byte] or raise "No delta for byte #{byte}!"
          puts "%02X        ; delta ##{byte} : dx = #{d[0]}, dy = #{d[1]}, da = #{d[2]}" % byte
          pos += 1
        end
      end
      puts "=== END OF SCRIPT ==="
    end

    private

    def register_delta(tuple)
      @deltas[tuple] += 1
    end

    def first_visible(slist)
      slist.index do |s|
        x, y = s[:s][0..1]
        x >= 0 && x < 344 && y >= 0
      end
    end

    def script_start
      @script = []
    end

    def script_state(values)
      @script << 0xC0 + 2 * (values[2] % 32) + (values[0] / 256)
      @script << values[0] % 256
      @script << values[1] % 256
    end

    def script_sleep(num_frames)
      div, rest = num_frames.divmod(63)
      div.times { @script << 0x80 + 63 }
      @script << 0x80 + rest if rest > 0
    end

    def script_delta(index)
      raise "Bad delta index: #{index}" if index < 0 || index > 127
      @script << index
    end

    def script_end
      @script << 0x80
    end
  end
end
