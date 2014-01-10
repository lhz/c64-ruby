module C64
  class DeltaEncoder

    attr_reader :num_objects, :steps, :deltas

    def initialize(num_objects, num_traits, options = {})
      @num_objects = num_objects
      @num_traits  = num_traits
      @ranges = options[:ranges] || [(-7..7)] * num_traits
      @steps  = Array.new(num_objects) { [] }
      @deltas = Hash.new { 0 }
    end

    # Record the state of an object for a new step
    def record_step(index, state)
      step = {s: state}
      if prev = @steps[index].last
        step[:d] = prev[:s].map.with_index {|value, i| state[i] - value}
        @deltas[step[:d]] += 1
      end
      @steps[index] << step
    end

    # Remove deltas with values outside the valid ranges
    def prune_deltas
      @deltas.delete_if do |key, value|
        key.map.with_index.any? {|delta, i| !@ranges[i].include? delta }
      end
    end

    def compile
      prune_deltas
      puts "STEPS: #{@steps[0].size}"
      puts "PRUNE: #{@deltas.inspect} (#{@deltas.size})"
    end

  end
end
