// JavaScript equivalent of the Ruby code

// Initialize points tracking variables
let points = 0;
let points_list = [];
let markers_list = [];
let locked = true;
let eta = 0;
let lower_slider_value = 0;
let upper_slider_value = 10;
let has_unsaved_changes = false;
let prev_second = 0;
let default_config = {
  autoReturnRatingsToZero: true  // Default setting to auto-return ratings to zero
};

let video_player;
let current_time_display;
let duration_display;
let points_display;
let seek_slider;
let pause_button;
let time_input;
let back10;
let forward10;
let back30;
let forward30;

// Format time function (converts seconds to MM:SS format)
function format_time(seconds) {
  const mins = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
}

function isPlaying() {
  return !(video_player.paused || video_player.ended);
}

function parse_time(time_str) {
  let seconds = 0;
  time_str = time_str.trim();
  
  // Handle formats like "1:20:30"
  if (/^\d{1,2}:\d{1,2}(:\d{1,2})?$/.test(time_str)) {
    const parts = time_str.split(":").map(part => parseInt(part, 10));
    parts.reverse();
    seconds += parts[0]; // seconds
    if (parts.length > 1) seconds += parts[1] * 60; // minutes
    if (parts.length > 2) seconds += parts[2] * 3600; // hours
  } else {
    // Handle formats like "1h 20m 30s" or "90s"
    const timeRegex = /(\d+)\s*(h|m|s)/gi;
    let match;
    
    while ((match = timeRegex.exec(time_str)) !== null) {
      const amount = parseInt(match[1], 10);
      const unit = match[2].toLowerCase();
      
      switch (unit) {
        case "h":
          seconds += amount * 3600;
          break;
        case "m":
          seconds += amount * 60;
          break;
        case "s":
          seconds += amount;
          break;
      }
    }
  }
  
  return seconds;
}

// Points functionality
function increase_points() {
  if (points < upper_slider_value) {
    points += 1;
    locked = false;
    eta = Date.now() / 1000;
    update_points_display();
  }
}

function decrease_points() {
  if (points > lower_slider_value) {
    points -= 1;
    locked = false;
    eta = Date.now() / 1000;
    update_points_display();
  }
}

function add_marker() {
  markers_list.push([Math.floor(video_player.currentTime * 1000), 1]);
  has_unsaved_changes = true;
}

function update_points_display() {
  console.log(`Updating points display: ${points}`);
  points_display.innerText = points.toString();
}

function save_data() {
  // Create a timestamp for the filename
  const now = new Date();
  const timestamp = now.toISOString().replace(/[T:.-]/g, "_").slice(0, 17);
  const filename = `psychometric_data_${timestamp}.json`;

  // Prepare data to save
  const data = {
    points: points_list,
    markers: markers_list,
    timestamp: timestamp
  };

  // Create a download link with the JSON data
  const json_str = JSON.stringify(data);
  const blob = new Blob([json_str], {type: "application/json"});
  const url = URL.createObjectURL(blob);

  // Create and trigger download
  const download_link = document.createElement("a");
  download_link.href = url;
  download_link.download = filename;
  document.body.appendChild(download_link);
  download_link.click();
  document.body.removeChild(download_link);

  has_unsaved_changes = false;
}

// Create UI elements for points functionality
function create_points_ui() {
  // Create container for points controls
  const points_container = document.createElement("div");
  points_container.className = "points-container";
  points_container.style.display = "flex";
  points_container.style.alignItems = "center";
  points_container.style.margin = "10px 0";

  // Create decrease button
  const dec_button = document.createElement("button");
  dec_button.innerText = "-";
  dec_button.className = "control-button";
  dec_button.addEventListener("click", decrease_points);

  // Create points display
  points_display = document.createElement("div");
  points_display.innerText = points.toString();
  points_display.style.margin = "0 10px";
  points_display.style.fontWeight = "bold";
  points_display.style.fontSize = "18px";
  points_display.style.width = "30px";
  points_display.style.textAlign = "center";

  // Create increase button
  const inc_button = document.createElement("button");
  inc_button.innerText = "+";
  inc_button.className = "control-button";
  inc_button.addEventListener("click", increase_points);

  // Create marker button
  const marker_button = document.createElement("button");
  marker_button.innerText = "Mark";
  marker_button.className = "control-button";
  marker_button.style.marginLeft = "10px";
  marker_button.addEventListener("click", add_marker);

  // Create save button
  const save_button = document.createElement("button");
  save_button.innerText = "Save";
  save_button.className = "control-button";
  save_button.style.marginLeft = "10px";
  save_button.addEventListener("click", save_data);

  // Create toggle for auto-return to zero
  const auto_return_container = document.createElement("div");
  auto_return_container.style.display = "flex";
  auto_return_container.style.alignItems = "center";
  auto_return_container.style.marginLeft = "10px";

  const auto_return_checkbox = document.createElement("input");
  auto_return_checkbox.type = "checkbox";
  auto_return_checkbox.id = "autoReturnCheckbox";
  auto_return_checkbox.checked = default_config.autoReturnRatingsToZero;
  auto_return_checkbox.addEventListener("change", (e) => {
    default_config.autoReturnRatingsToZero = e.target.checked;
  });

  const auto_return_label = document.createElement("label");
  auto_return_label.htmlFor = "autoReturnCheckbox";
  auto_return_label.innerText = "Auto-return to zero";
  auto_return_label.style.marginLeft = "5px";
  auto_return_label.style.fontSize = "12px";

  auto_return_container.appendChild(auto_return_checkbox);
  auto_return_container.appendChild(auto_return_label);

  // Add elements to container
  points_container.appendChild(dec_button);
  points_container.appendChild(points_display);
  points_container.appendChild(inc_button);
  points_container.appendChild(marker_button);
  points_container.appendChild(save_button);
  points_container.appendChild(auto_return_container);

  // Add container to the document
  const controls_section = document.querySelector(".controls");
  controls_section.appendChild(points_container);

  // Add keyboard shortcuts
  document.addEventListener("keydown", (e) => {
    switch (e.key) {
      case "ArrowUp":
        increase_points();
        break;
      case "ArrowDown":
        decrease_points();
        break;
      case "m":
        add_marker();
        break;
      case "s":
        if (e.ctrlKey || e.metaKey) save_data();
        break;
    }
  });

  // Add button to release lock (similar to Python app)
  document.addEventListener("keyup", (e) => {
    if (e.key === "ArrowUp" || e.key === "ArrowDown") {
      locked = false;
    }
  });
}

// Initialize the application
function initApp() {
  // Initialize document elements
  document.getElementById("spinner").style.display = "none";
  document.querySelector("section").style.display = "flex";
  
  video_player = document.getElementById("videoPlayer");
  current_time_display = document.getElementById("currentTime");
  duration_display = document.getElementById("duration");
  
  // Handle video file selection and setting the video source
  const video_file_element = document.getElementById("videoFile");
  
  if (video_file_element) {
    video_file_element.addEventListener("change", (event) => {
      const file = event.target.files[0];
      if (file) {
        const url = URL.createObjectURL(file);
        video_player.src = url;
      }
    });
    
    // Trigger change event to handle any pre-selected file
    video_file_element.dispatchEvent(new Event("change"));
  } else {
    console.error("Video file element not found");
  }
  
  pause_button = document.querySelector(".pauseButton");
  
  if (pause_button) {
    pause_button.addEventListener("click", () => {
      if (video_player.paused) {
        video_player.play();
      } else if (video_player.ended) {
        video_player.currentTime = 0;
        video_player.play();
      } else {
        video_player.pause();
      }
    });
  }
  
  // Handle playback rate adjustments from speed buttons
  const speed_buttons = document.querySelectorAll(".speedButton");
  Array.from(speed_buttons).forEach(button => {
    button.addEventListener("click", () => {
      Array.from(speed_buttons).forEach(btn => btn.style.backgroundColor = "");
      // Highlight the clicked button
      button.style.backgroundColor = "#4CAF50";

      const speed = button.getAttribute("data-speed");
      video_player.playbackRate = parseFloat(speed);
      video_player.play();
    });
  });
  
  seek_slider = document.getElementById("seekSlider");
  if (seek_slider) {
    seek_slider.value = 0;
    
    // Update video position when slider value changes
    seek_slider.addEventListener("input", () => {
      video_player.currentTime = parseFloat(seek_slider.value);
      current_time_display.innerText = format_time(video_player.currentTime);
    });
  }
  
  // Update the slider max value based on the video duration
  if (video_player) {
    video_player.addEventListener("loadedmetadata", () => {
      if (seek_slider) {
        seek_slider.max = video_player.duration;
      }
      if (duration_display) {
        duration_display.innerText = format_time(video_player.duration);
      }
    });
    
    video_player.addEventListener("play", () => {
      if (pause_button) {
        pause_button.innerText = "Pause";
      }
    });
    
    video_player.addEventListener("pause", () => {
      if (pause_button) {
        pause_button.innerText = "Play";
      }
    });
    
    // Update slider position as the video plays
    video_player.addEventListener("timeupdate", () => {
      if (seek_slider && seek_slider !== document.activeElement) {
        seek_slider.value = video_player.currentTime;
      }
      if (current_time_display) {
        current_time_display.innerText = format_time(video_player.currentTime);
      }
  
      // Record points at each second
      const current_second = Math.floor(video_player.currentTime);
      if (current_second !== prev_second && !video_player.paused) {
        points_list.push([Math.floor(video_player.currentTime * 1000), points]);
        has_unsaved_changes = true;
  
        // Auto return ratings to zero if enabled
        if (default_config.autoReturnRatingsToZero && locked === false && (Date.now() / 1000 - eta) >= 2) {
          console.log("Auto-returning to zero");
          if (points > 0) {
            points -= 1;
            update_points_display();
          } else if (points < 0) {
            points += 1;
            update_points_display();
          }
        }
  
        prev_second = current_second;
        update_points_display();
      }
    });
  }
  
  time_input = document.getElementById("timeInput");
  if (time_input) {
    time_input.value = "";
    
    time_input.addEventListener("change", () => {
      const input_time = parse_time(time_input.value);
      if (input_time) {
        video_player.currentTime = input_time;
      }
    });
    
    time_input.addEventListener("keypress", (e) => {
      if (e.key === "Enter") {
        time_input.dispatchEvent(new Event("change"));
      }
    });
  }
  
  back10 = document.getElementById("back10");
  forward10 = document.getElementById("forward10");
  back30 = document.getElementById("back30");
  forward30 = document.getElementById("forward30");
  
  // Event listeners for the jump buttons
  if (back10) {
    back10.addEventListener("click", () => {
      const new_time = Math.max(video_player.currentTime - 10, 0);
      video_player.currentTime = new_time;
      if (seek_slider) seek_slider.value = new_time;
    });
  }
  
  if (forward10) {
    forward10.addEventListener("click", () => {
      const max_time = video_player.duration;
      const new_time = Math.min(video_player.currentTime + 10, max_time);
      video_player.currentTime = new_time;
      if (seek_slider) seek_slider.value = new_time;
    });
  }
  
  if (back30) {
    back30.addEventListener("click", () => {
      const new_time = Math.max(video_player.currentTime - 30, 0);
      video_player.currentTime = new_time;
      if (seek_slider) seek_slider.value = new_time;
    });
  }
  
  if (forward30) {
    forward30.addEventListener("click", () => {
      const max_time = video_player.duration;
      const new_time = Math.min(video_player.currentTime + 30, max_time);
      video_player.currentTime = new_time;
      if (seek_slider) seek_slider.value = new_time;
    });
  }
  
  create_points_ui();
  update_points_display();
}

// Initialize the UI when the DOM is loaded
document.addEventListener("DOMContentLoaded", () => {
  initApp();
});

// If the DOM is already loaded, initialize immediately
if (document.readyState === "complete" || document.readyState === "interactive") {
  initApp();
}
