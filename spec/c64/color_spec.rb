require 'c64/color'

describe C64::Color do

  include C64::Color::Methods
  class TestNames; include C64::Color::Names; end

  describe C64::Color::Names do
    it "exposes color names as constants" do
      TestNames.const_get('LIGHT_BLUE').should eq 14
    end
  end

  describe C64::Color::Methods do
    it "adds method #color to Symbol, returning color index" do
      :blue.should respond_to(:color)
      :blue.color.should eq 6
    end
    it "adds method #color to Fixnum, returning color index" do
      0xF0F020.should respond_to(:color)
      0xF0F020.color.should eq 7
    end
    it "adds method #rgb to Fixnum, returning 32-bit RGB value" do
      4.should respond_to(:rgb)
      4.rgb.should eq 0x6F3D86
      4.rgb(:vice).should eq 0xB41AE2
    end
  end

  describe "from_symbol" do
    it "takes lowercase symbols" do
      subject.from_symbol(:light_red).should eq 10
    end
    it "takes uppercase symbols" do
      subject.from_symbol(:PURPLE).should eq 4
    end
  end

  describe "from_rgba" do
    it "delegates to from_rgb without the alpha component" do
      subject.should_receive(:from_rgb).with(0x123456, nil).once
      subject.from_rgba(0x12345678)
      subject.should_receive(:from_rgb).with(0x010203, 123).once
      subject.from_rgba(0x010203FF, 123)
    end
  end

  describe "from_rgb" do
    it "looks up index in palette and returns it" do
      subject.should_not_receive(:guess_from_rgb)
      subject.from_rgb(0x8F8F8F).should eq 15
    end
    it "looks up index in palette and uses passed default when not found" do
      subject.should_not_receive(:guess_from_rgb)
      subject.from_rgb(0x123456, 123).should eq 123
    end
    it "looks up index in palette and calls guess_from_rgb when not found" do
      subject.should_receive(:guess_from_rgb).with(0x123456).once
      subject.from_rgb(0x123456)
    end
  end

  describe "to_rgb" do
    it "returns the RGB value of the given index using the default palette" do
      subject.to_rgb(14).should eq(0X6C5EB5)
    end
    it "returns the RGB value of the given index using the specified palette" do
      subject.to_rgb(14, :vice).should eq(0x5F53FE)
    end
  end

  describe "merged_palettes" do
    it "returns a hash with 24-bit color values as keys" do
      subject.merged_palettes.keys.all? {|k| (0...2**24).include? k }.should be_true
    end
    it "returns a hash with at least 16 distinct keys" do
      subject.merged_palettes.keys.sort.uniq.size.should be >= 16
    end
    it "returns a hash with C64 color indices as values" do
      subject.merged_palettes.values.all? {|v| (0..15).include? v }.should be_true
    end
  end

  # Run the below code in REPL to debug HSL values for palette
  #
  #   C64::Color.palette_vice_old.each do |rgb, i|
  #     h, s, l = C64::Color.send(:rgb_to_hsl, rgb)
  #     puts "%02d   %06X   %5.1f  %5.3f  %5.3f" % [i, rgb, h, s, l]
  #   end
  #
  describe "guess_from_rgb" do
    it "correctly guesses the index of all colors in the palettes" do
      subject.merged_palettes.each do |rgb, index|
        subject.guess_from_rgb(rgb).should eq index
      end
    end
    it "correctly guesses the index of colors not in the palette" do
      colors = {
        0xFF4040 => 10, 0x60F060 => 13, 0x101050 =>  6, 0xD0D000 =>  7,
        0x702020 =>  2, 0x208020 =>  5, 0x4040E0 => 14, 0x101010 =>  0,
        0xD000D0 =>  4, 0x00D0D0 =>  3, 0xC0A020 =>  8, 0x504020 =>  9,
        0xF0F0F0 =>  1, 0xA0A0A0 => 15, 0x707070 => 12, 0x404040 => 11,
      }
      colors.each do |rgb, index|
        subject.guess_from_rgb(rgb).should eq index
      end
    end
  end

  describe "xterm256_escape" do
    it "maps an index into an ANSI sequence to set foreground color" do
      subject.xterm256_escape(3).should eq "\033[38;5;6m"
    end
    it "maps an index into an ANSI sequence to set background color" do
      subject.xterm256_escape(7, true).should eq "\033[48;5;185m"
    end
  end

  describe "xterm256_dump" do
    it "starts with an ANSI sequence to set background color" do
      subject.should_receive(:xterm256_escape).with(4, true).once.and_call_original
      subject.xterm256_dump(4)
    end
    it "ends with a sequence of spaces" do
      subject.xterm256_dump(4).should end_with("  ")
      subject.xterm256_dump(4, true).should end_with("    ")
    end
  end

end
