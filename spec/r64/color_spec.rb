require 'r64/color'

describe R64::Color do

  describe "from_symbol" do
    it "takes lowercase symbols" do
      subject.from_symbol(:light_red).should eq 10
    end
    it "takes uppercase symbols" do
      subject.from_symbol(:PURPLE).should eq 4
    end
  end

  describe "xterm_ansi" do
    it "maps an index into an ANSI sequence to set foreground color" do
      subject.xterm_ansi(3).should eq "\033[38;5;6m"
    end
    it "maps an index into an ANSI sequence to set background color" do
      subject.xterm_ansi(7, true).should eq "\033[48;5;185m"
    end
  end

  describe "xterm_dump" do
    it "starts with an ANSI sequence to set background color" do
      subject.should_receive(:xterm_ansi).with(4, true).once.and_call_original
      subject.xterm_dump(4)
    end
    it "ends with a sequence of spaces" do
      subject.xterm_dump(4).should end_with("  ")
      subject.xterm_dump(4, true).should end_with("    ")
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
      subject.should_receive(:palette).once.and_call_original
      subject.should_not_receive(:guess_from_rgb)
      subject.from_rgb(0x8F8F8F).should eq 15
    end
    it "looks up index in palette and uses passed default if not found" do
      subject.should_receive(:palette).once.and_call_original
      subject.should_not_receive(:guess_from_rgb)
      subject.from_rgb(0x123456, 123).should eq 123
    end
    it "looks up index in palette and calls guess_from_rgb if not found" do
      subject.should_receive(:palette).once.and_call_original
      subject.should_receive(:guess_from_rgb).with(0x123456).once
      subject.from_rgb(0x123456)
    end
  end

  describe "palette" do
    it "returns a hash with 24-bit color values as keys" do
      subject.palette.keys.should include(0xD5D5D5)
      subject.palette.keys.should include(0x6C5EB5)
    end
    it "returns a hash with at least 16 distinct keys" do
      subject.palette.keys.sort.uniq.size.should be >= 16
    end
    it "returns a hash with C64 color indices as values" do
      subject.palette.values.all? {|v| (0..15).include? v }.should be_true
    end
  end

  describe "guess_from_rgb" do
    it "correctly guesses the index of all colors in the palette" do
      subject.palette.each do |rgb, index|
        subject.guess_from_rgb(rgb).should eq index
      end
    end
    it "correctly guesses the index of colors not in the palette" do
      colors = {
        0xFF4040 => 10, 0x30E030 => 13, 0x101050 =>  6, 0xD0D000 =>  7,
        0x702020 =>  2, 0x208020 =>  5, 0x4040E0 => 14, 0x101010 =>  0,
        0xD000D0 =>  4, 0x00D0D0 =>  3, 0xC0A020 =>  9, 0x806040 =>  8,
        0xF0F0F0 =>  1, 0xA0A0A0 => 15, 0x707070 => 12, 0x404040 => 11,
      }
      colors.each do |rgb, index|
        subject.guess_from_rgb(rgb).should eq index
      end
    end
  end

end
