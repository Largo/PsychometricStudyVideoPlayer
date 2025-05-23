require "js"
require "js/require_remote"
require "json"

module Kernel
  alias_method :original_require_relative, :require_relative
  def require_relative(path)
    JS::RequireRemote.instance.load(path)
  end
end
app_path = __FILE__
$0 = File.basename(app_path, ".rb") if app_path
@document = JS.global.document

@document.getElementById("spinner").style.display = "none"
@document.querySelector("section").style.display = "flex"

# Initialize points tracking variables
@points = 0
@points_list = []
@markers_list = []
@locked = true
@eta = 0
@lower_slider_value = 0
@upper_slider_value = 10
@has_unsaved_changes = false
@prev_second = 0
@default_config = {
  "autoReturnRatingsToZero" => true  # Default setting to auto-return ratings to zero
}

@video_player = @document.getElementById("videoPlayer")
@current_time_display = @document.getElementById("currentTime")
@duration_display = @document.getElementById("duration")

def format_time(seconds)
  mins = (seconds / 60).floor
  secs = (seconds % 60).floor
  "%02d:%02d" % [mins, secs]
end

# Handle video file selection and setting the video source
video_file_element = @document.getElementById("videoFile")

video_file_element.addEventListener("change") do |event|
  file = event.target.files[0]
  if file && !file.undefined?
    url = JS.global.URL.createObjectURL(file)
    video_player = @document.getElementById("videoPlayer")
    video_player.src = url
  end
end

video_file_element.dispatchEvent(JS.global.Event.new("change"))

@pause_button = @document.querySelector(".pauseButton")
def isPlaying?
  !(@video_player.paused? || @video_player.ended?)
end

@pause_button.addEventListener("click") do
  if @video_player.paused?
    @video_player.play
  elsif @video_player.ended?
    @video_player.currentTime = 0
    @video_player.play

  else
    @video_player.pause
  end
end

# Handle playback rate adjustments from speed buttons
speed_buttons = @document.querySelectorAll(".speedButton")
speed_buttons.to_a.each do |button|
  button.addEventListener("click") do
    speed_buttons.to_a.each { |btn| btn.style.backgroundColor = "" }
    # Highlight the clicked button
    button.style.backgroundColor = "#4CAF50"

    speed = button.getAttribute("data-speed")
    @video_player.playbackRate = speed.to_f
    @video_player.play
  end
end

@video_player = @document.getElementById("videoPlayer")
@seek_slider = @document.getElementById("seekSlider")
@seek_slider.value = 0
# Update the slider max value based on the video duration
@video_player.addEventListener("loadedmetadata") do
  @seek_slider.max = @video_player.duration
  @duration_display.innerText = format_time(@video_player.duration)
end

# Update video position when slider value changes
@seek_slider.addEventListener("input") do
  @video_player.currentTime = @seek_slider.value.to_f
  @current_time_display.innerText = format_time(@video_player.currentTime)
end

@video_player.addEventListener("play") do
  @pause_button.innerText = "Pause"
end
@video_player.addEventListener("pause") do
  @pause_button.innerText = "Play"
end

# Update slider position as the video plays
@video_player.addEventListener("timeupdate") do
  @seek_slider.value = @video_player.currentTime unless @seek_slider === @document.activeElement
  @current_time_display.innerText = format_time(@video_player.currentTime)

  # Record points at each second
  current_second = @video_player.currentTime.floor
  if current_second != @prev_second && !@video_player.paused?
    @points_list.push([(@video_player.currentTime * 1000).to_i, @points])
    @has_unsaved_changes = true

    # Auto return ratings to zero if enabled (similar to Python app)
    if @default_config["autoReturnRatingsToZero"] && @locked == false && (Time.now.to_f - @eta) >= 2
      JS.global.console.log("Auto-returning to zero")
      if @points > 0
        @points -= 1
        update_points_display
      elsif @points < 0
        @points += 1
        update_points_display
      end
    end

    @prev_second = current_second
    update_points_display
  end
end

@seek_slider = @document.getElementById("seekSlider")
@time_input = @document.getElementById("timeInput")
@time_input.value = ""
@time_input.addEventListener("change") do
  input_time = parse_time(@time_input.value)
  if input_time
    @video_player.currentTime = input_time
  end
end

@time_input.addEventListener("keypress") do |e|
  if e.key === "Enter"
    @time_input.dispatchEvent(JS.global.Event.new("change"))
  end
end

def parse_time(time_str)
  seconds = 0
  time_str.strip!
  # Handle formats like "1:20:30"
  if /\A\d{1,2}:\d{1,2}(:\d{1,2})?\z/.match?(time_str)
    parts = time_str.split(":").map(&:to_i)
    parts.reverse!
    seconds += parts[0] # seconds
    seconds += parts[1] * 60 if parts.length > 1 # minutes
    seconds += parts[2] * 3600 if parts.length > 2 # hours
  else
    # Handle formats like "1h 20m 30s" or "90s"
    time_str.scan(/(\d+)\s*(h|m|s)/i).each do |amount, unit|
      amount = amount.to_i
      case unit.downcase
      when "h"
        seconds += amount * 3600
      when "m"
        seconds += amount * 60
      when "s"
        seconds += amount
      end
    end
  end
  seconds
end

# Points functionality
def increase_points
  if @points < @upper_slider_value
    @points += 1
    @locked = false
    @eta = Time.now.to_f
    update_points_display
  end
end

def decrease_points
  if @points > @lower_slider_value
    @points -= 1
    @locked = truefalse
    @eta = Time.now.to_f
    update_points_display
  end
end

def add_marker
  @markers_list.push([(@video_player.currentTime * 1000).to_i, 1])
  @has_unsaved_changes = true
end

def update_points_display
  JS.global.console.log("Updating points display: #{@points}")
  @points_display.innerText = @points.to_s
end

def save_data
  # Create a timestamp for the filename
  timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
  filename = "psychometric_data_#{timestamp}.json"

  # Prepare data to save
  data = {
    points: @points_list,
    markers: @markers_list,
    timestamp: timestamp
  }

  # Create a download link with the JSON data
  json_str = JSON.generate(data)
  blob = JS.global.Blob.new([json_str], {type: "application/json"})
  url = JS.global.URL.createObjectURL(blob)

  # Create and trigger download
  download_link = @document.createElement("a")
  download_link.href = url
  download_link.download = filename
  @document.body.appendChild(download_link)
  download_link.click()
  @document.body.removeChild(download_link)

  @has_unsaved_changes = false
end

# Create UI elements for points functionality
def create_points_ui
  # Create container for points controls
  points_container = @document.createElement("div")
  points_container.className = "points-container"
  points_container.style.display = "flex"
  points_container.style.alignItems = "center"
  points_container.style.margin = "10px 0"

  # Create decrease button
  dec_button = @document.createElement("button")
  dec_button.innerText = "-"
  dec_button.className = "control-button"
  dec_button.addEventListener("click") { decrease_points }

  # Create points display
  @points_display = @document.createElement("div")
  @points_display.innerText = @points.to_s
  @points_display.style.margin = "0 10px"
  @points_display.style.fontWeight = "bold"
  @points_display.style.fontSize = "18px"
  @points_display.style.width = "30px"
  @points_display.style.textAlign = "center"

  # Create increase button
  inc_button = @document.createElement("button")
  inc_button.innerText = "+"
  inc_button.className = "control-button"
  inc_button.addEventListener("click") { increase_points }

  # Create marker button
  marker_button = @document.createElement("button")
  marker_button.innerText = "Mark"
  marker_button.className = "control-button"
  marker_button.style.marginLeft = "10px"
  marker_button.addEventListener("click") { add_marker }

  # Create save button
  save_button = @document.createElement("button")
  save_button.innerText = "Save"
  save_button.className = "control-button"
  save_button.style.marginLeft = "10px"
  save_button.addEventListener("click") { save_data }

  # Create toggle for auto-return to zero
  auto_return_container = @document.createElement("div")
  auto_return_container.style.display = "flex"
  auto_return_container.style.alignItems = "center"
  auto_return_container.style.marginLeft = "10px"

  auto_return_checkbox = @document.createElement("input")
  auto_return_checkbox.type = "checkbox"
  auto_return_checkbox.id = "autoReturnCheckbox"
  auto_return_checkbox.checked = @default_config["autoReturnRatingsToZero"]
  auto_return_checkbox.addEventListener("change") do |e|
    @default_config["autoReturnRatingsToZero"] = e.target.checked
  end

  auto_return_label = @document.createElement("label")
  auto_return_label.htmlFor = "autoReturnCheckbox"
  auto_return_label.innerText = "Auto-return to zero"
  auto_return_label.style.marginLeft = "5px"
  auto_return_label.style.fontSize = "12px"

  auto_return_container.appendChild(auto_return_checkbox)
  auto_return_container.appendChild(auto_return_label)

  # Add elements to container
  points_container.appendChild(dec_button)
  points_container.appendChild(@points_display)
  points_container.appendChild(inc_button)
  points_container.appendChild(marker_button)
  points_container.appendChild(save_button)
  points_container.appendChild(auto_return_container)

  # Add container to the document
  controls_section = @document.querySelector(".controls")
  controls_section.appendChild(points_container)

  # Add keyboard shortcuts
  @document.addEventListener("keydown") do |e|
    case e.key
    when "ArrowUp"
      increase_points
    when "ArrowDown"
      decrease_points
    when "m"
      add_marker
    when "s"
      save_data if e.ctrlKey || e.metaKey
    end
  end

  # Add button to release lock (similar to Python app)
  @document.addEventListener("keyup") do |e|
    case e.key
    when "ArrowUp", "ArrowDown"
      @locked = false
    end
  end
end

@back10 = @document.getElementById("back10")
@forward10 = @document.getElementById("forward10")
@back30 = @document.getElementById("back30")
@forward30 = @document.getElementById("forward30")

# Event listeners for the jump buttons
@back10.addEventListener("click") do
  new_time = [@video_player.currentTime - 10, 0].max
  @video_player.currentTime = new_time
  @seek_slider.value = new_time
end

@forward10.addEventListener("click") do
  max_time = @video_player.duration
  new_time = [@video_player.currentTime + 10, max_time].min
  @video_player.currentTime = new_time
  @seek_slider.value = new_time
end

@back30.addEventListener("click") do
  new_time = [@video_player.currentTime - 30, 0].max
  @video_player.currentTime = new_time
  @seek_slider.value = new_time
end

@forward30.addEventListener("click") do
  max_time = @video_player.duration
  new_time = [@video_player.currentTime + 30, max_time].min
  @video_player.currentTime = new_time
  @seek_slider.value = new_time
end

# The DOM is likely already loaded at this point
create_points_ui
update_points_display
