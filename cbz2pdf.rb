require 'bundler/setup'
Bundler.require

require 'zip'
require 'tempfile'

def extract_images_from_cbz(cbz_file_path)
  images = []
  Tempfile.create(File.basename(cbz_file_path)) do |tempfile|
    File.write(tempfile.path, File.read(cbz_file_path, mode: 'rb'))
    Zip::File.open(tempfile.path) do |zip_file|
      zip_file.each do |entry|
        next unless entry.name =~ /\.(jpg|jpeg|png|gif)$/i
        images << entry.get_input_stream.read
      end
    end
  end
  images
end

def convert_and_resize_image(image_data, width, height, force_aspect_ratio = false)
  img = Magick::Image.from_blob(image_data).first

  # Force aspect ratio 4:3
  if force_aspect_ratio
    fit_img = img.resize_to_fit!(width, height)
    padded_img = ::Magick::Image.new(width, height)
    filled = padded_img.matte_floodfill(1, 1)
    img = filled.composite!(fit_img, ::Magick::CenterGravity, ::Magick::OverCompositeOp)    
  else
    img.resize_to_fit!(width, height) # Resize to fit within max dimensions
  end

  # Convert to grayscale
  img.quantize(256, Magick::GRAYColorspace)
end

def create_pdf_from_images(images, pdf_file_path, max_width, max_height)
  pdf = Magick::ImageList.new
  force_aspect_ratio = true

  images.each_with_index do |image, index|
    if index == 0 # First image (cover)
      pdf << convert_and_resize_image(image, max_width, max_width * 4 / 3, force_aspect_ratio)
    else
      pdf << convert_and_resize_image(image, max_width, max_height)
    end
  end

  pdf.write(pdf_file_path)
end

if ARGV.length < 2
  puts "Usage: ruby cbz2pdf.rb <input_file.cbz> -o <output_file.pdf>"
  exit 1
end

cbz_file_path = ARGV.shift
output_index = ARGV.index('-o') || ARGV.index('--output')
pdf_file_path = ARGV[output_index + 1]

images = extract_images_from_cbz(cbz_file_path)
# Set the target width and height for resizing
# 1404x1872 = reMarkable 2
create_pdf_from_images(images, pdf_file_path, 1404, 1872)

puts "Conversion complete. PDF file saved to: #{pdf_file_path}"
