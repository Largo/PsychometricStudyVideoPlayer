require 'js'
require 'js/require_remote'

module Kernel
    alias original_require_relative require_relative
    def require_relative(path)
        JS::RequireRemote.instance.load(path)
    end
end
app_path = __FILE__
$0 = File::basename(app_path, ".rb") if app_path
#require_relative "require/second" # Here it should be relative to main.rb. Note: I will upstream the fix for this.

JS.global.document.getElementById("spinner").style.display = "none"
#JS.global.document.querySelector(".buttons").style.display = "block"

 # Handle video file selection and setting the video source
 video_file_element = JS.global.document.getElementById('videoFile')
 video_file_element.addEventListener('change') do |event|
   file = event.target.files[0]
   if file
     url = JS.global.URL.createObjectURL(file)
     video_player = JS.global.document.getElementById('videoPlayer')
     video_player.src = url
   end
 end

 # Handle playback rate adjustments from speed buttons
 speed_buttons = JS.global.document.querySelectorAll('.speedButton')
 speed_buttons.to_a.each do |button|
   button.addEventListener('click') do
     speed = button.getAttribute('data-speed')
     video_player = JS.global.document.getElementById('videoPlayer')
     video_player.playbackRate = speed.to_f
   end
 end