require 'c64'
require 'c64/image'

include C64::Color::Names

describe C64::Image do

  context "class" do
    describe "contructor" do
      it "takes a filename parameter" do
        ChunkyPNG::Image.stub(:from_file)
        expect { C64::Image.new('filename') }.not_to raise_error
      end
    end
  end

  context "instance" do

    let(:image_file) { 'spec/fixtures/palette.png' }
    let(:hires_file) { 'spec/fixtures/hires-font.png' }
    let(:image_png) { ChunkyPNG::Image.from_file image_file }
    let(:hires_png) { ChunkyPNG::Image.from_file hires_file }
    let(:image) { C64::Image.new image_file }
    let(:hires) { C64::Image.new hires_file }

    describe "#width" do
      it "returns the width of the image" do
        image.width.should eq image_png.width
      end
    end

    describe "#height" do
      it "returns the height of the image" do
        image.height.should eq image_png.height
      end
    end

    describe "#char_width" do
      it "returns the width of the image in chars" do
        image.char_width.should eq image_png.width / 8
      end
    end

    describe "#char_height" do
      it "returns the width of the image in chars" do
        image.char_height.should eq image_png.height / 8
      end
    end

    describe "#pixel_width" do
      it "returns 1 for a hires image" do
        hires.pixel_width.should eq 1
      end
      it "returns 2 for a multicolor image" do
        image.pixel_width.should eq 2
      end
    end

    describe "#pixel_width=" do
      it "overrides the detected pixel width" do
        [1, 2].each do |value|
          image.pixel_width = value
          image.pixel_width.should eq value
        end
      end
      it "accepts values 1 and 2 only" do
        [0, 1.5, 2.01, 3].each do |value|
          expect { image.pixel_width = value }.to raise_error
        end
      end
    end

    describe "#[]" do
      it "returns the color index of individual pixels" do
        expected = {
          [ 8,  0] => RED,
          [12,  4] => YELLOW,
          [ 0,  8] => ORANGE,
          [ 4, 12] => LIGHT_GREEN,
        }
        expected.each do |pos, color|
          image[pos.first, pos.last].should eq color
        end
      end
      it "raises IndexError when out of bounds" do
        [[-1, 0], [0, -1], [image.width, 0], [0, image.height]].each do |pos|
          expect { image[pos.first, pos.last] }.to raise_error(IndexError)
        end
      end
    end

  end
end
