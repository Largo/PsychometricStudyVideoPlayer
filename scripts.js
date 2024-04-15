document.getElementById('videoFile').addEventListener('change', function(event) {
    const file = event.target.files[0];
    if (file) {
        const url = URL.createObjectURL(file);
        const videoPlayer = document.getElementById('videoPlayer');
        videoPlayer.src = url;
    }
});

const speedButtons = document.querySelectorAll('.speedButton');
speedButtons.forEach(button => {
    button.addEventListener('click', function() {
        const speed = this.getAttribute('data-speed');
        const videoPlayer = document.getElementById('videoPlayer');
        videoPlayer.playbackRate = parseFloat(speed);
    });
});
