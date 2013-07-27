class C64::Memory

  attr_reader :chunks

  def initialize(fill = 0)
    @memory = Array.new(256 * 256) { nil }
    @chunks = []
    @fill = fill
  end

  def inject(label, data, address = nil)
    from = address || (data.shift + 256 * data.shift)
    size = data.size
    to   = from + size - 1
    raise "Data for '#{label}' does not fit into memory!" if to > 0xFFFF
    @memory[from, size] = data
    add_chunk(label, from, to, size)
  end

  def add_chunk(label, from, to, size)
    ai = @chunks.index {|c| c[:to] == from - 1 }
    pi = @chunks.index {|c| c[:from] == to + 1 }
    if ai && pi
      # Adjoin two existing chunks
      @chunks[ai][:to] = @chunks[pi][:to]
      @chunks[ai][:size] += size + @chunks[pi][:size]
      @chunks[ai][:labels] += [label] + @chunks[pi][:labels]
      @chunks.delete_at(pi)
    elsif ai
      # Append to an existing chunk
      @chunks[ai][:to] = to
      @chunks[ai][:size] += size
      @chunks[ai][:labels].push label
    elsif pi
      # Prepend to an existing chunk
      @chunks[pi][:from] = from
      @chunks[pi][:size] += size
      @chunks[pi][:labels].unshift label
    else
      # New chunk
      @chunks << { from: from, to: to, size: size, labels: [label] }
    end
    @cmin, @cmax = [from, to, @cmin || from, @cmax || to].minmax
  end

  def inject_file(filename)
    content = File.read(filename).bytes.to_a
    inject(File.basename(filename), content)
  end

  def min_used
    @chunks.map {|c| c[:from]}.min
  end

  def max_used
    @chunks.map {|c| c[:to]}.max
  end

  def to_prg
    [min_used].pack('S') +
      @memory[min_used..max_used].map {|b| b || @fill }.pack('C*')
  end

end
