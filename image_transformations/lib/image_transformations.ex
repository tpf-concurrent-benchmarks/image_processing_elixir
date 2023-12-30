defmodule ImageTransformations do

  def handle_image(img_name) do
    f_input_img = "img/input/#{img_name}"
    img_name_noext = String.split(img_name, ".") |> List.first
    f_formatted_img = "img/formatted/#{img_name_noext}.png"
    f_scaled_img = "img/scaled/#{img_name_noext}.png"
    f_resized_img = "img/output/#{img_name_noext}.png"

    input_img = Image.open!(f_input_img)
    Image.write(input_img, f_formatted_img)

    formatted_img = Image.open!(f_formatted_img)
    scaled_img = Image.thumbnail!(formatted_img, "100x100", fit: :fill)
    Image.write(scaled_img, f_scaled_img)

    resized_img = Image.center_crop!(scaled_img, 30, 30)
    Image.write(resized_img, f_resized_img)

  end

  def main do
    # Read filenames in img/input and pass them to handle_image

    File.ls!("img/input")
     |> Enum.map(fn filename ->
       handle_image(filename)
     end)

  end

end
