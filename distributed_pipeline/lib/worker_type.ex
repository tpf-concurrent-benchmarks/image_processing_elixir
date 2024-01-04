defmodule WorkerBehaviour do
  @callback do_work(any()) :: any()
  @callback handle_file_path(any()) :: any()
end



defmodule FormatWorker do
  @behaviour WorkerBehaviour

  def do_work(work) do
    Enum.map(work, &handle_file_path/1)
  end

  def handle_file_path(file_path) do
    file_name = Path.basename(file_path)
    file_name_noext = String.split(file_name, ".") |> List.first
    output_file_path = "shared/formatted/#{file_name_noext}.png"

    image = Image.open!(file_path)
    Image.write(image, output_file_path)

    output_file_path
  end
end

defmodule ResolutionWorker do
  @behaviour WorkerBehaviour

  def do_work(work) do
    Enum.map(work, &handle_file_path/1)
  end

  def handle_file_path(file_path) do
    file_name = Path.basename(file_path)
    output_file_path = "shared/scaled/#{file_name}"

    image = Image.open!(file_path)
    scaled_img = Image.thumbnail!(image, "100x100", fit: :fill)
    Image.write(scaled_img, output_file_path)

    output_file_path
  end
end

defmodule SizeWorker do
  @behaviour WorkerBehaviour

  def do_work(work) do
    Enum.map(work, &handle_file_path/1)
  end

  def handle_file_path(file_path) do
    file_name = Path.basename(file_path)
    output_file_path = "shared/output/#{file_name}"

    image = Image.open!(file_path)
    resized_img = Image.center_crop!(image, 30, 30)
    Image.write(resized_img, output_file_path)

    output_file_path
  end
end
