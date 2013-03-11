require 'r64/color'

describe R64::Color do

  describe "guess_from_rgb" do
    it "correctly guesses the index of all colors in the palette" do
      subject.palette.each do |rgb, index|
        subject.guess_from_rgb(rgb).should eq index
      end
    end
    it "correctly guesses the index of some colors not in the palette" do
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
