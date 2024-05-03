require "js"
require "js/require_remote"

module Kernel
  alias_method original_require_relative require_relative
  def require_relative(path)
    JS::RequireRemote.instance.load(path)
  end
end
app_path = __FILE__
$0 = File.basename(app_path, ".rb") if app_path
@document = JS.global.document

@document.getElementById("spinner").style.display = "none"
@document.querySelector("section").style.display = "flex"

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
