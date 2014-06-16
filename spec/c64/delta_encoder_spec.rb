require 'c64/delta_encoder'

describe C64::DeltaEncoder do

  describe "#prune_deltas" do
    # let(:ranges) do
    #   [(0..3), (0..5)]
    # end
    # let(:deltas) do
    #   [[[ 2, 1], [ 5, 0], [ 1, 2], [ 1, 6]],
    #    [[ 1, 3], [ 1,-2], [ 5, 1], [-1, 2]]]
    # end
    # let(:deltas_invalid) do
    #   [[5, 0], [1, 6], [1, -2], [5, 1], [-1, 2]]
    # end
    # let(:deltas_valid) do
    #   deltas.flatten(1).uniq - deltas_invalid
    # end
    # before do
    #   @enc = C64::DeltaEncoder.new(deltas.size, 2, ranges: ranges)
    #   deltas.each_with_index do |dlist, obj_index|
    #     @enc.record_step obj_index, [x = 0, y = 0]
    #     dlist.each {|d| @enc.record_step obj_index, [x += d[0], y += d[1]] }
    #   end
    #   @enc.prune_deltas
    # end
    # it "removes all deltas outside the given ranges" do
    #   deltas_invalid.each {|d| @enc.deltas.should_not have_key(d) }
    # end
    # it "retains all deltas inside the given ranges" do
    #   deltas_valid.each {|d| @enc.deltas.should have_key(d) }
    # end
  end

end
