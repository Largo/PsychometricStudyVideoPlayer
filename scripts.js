document.getElementById('videoFile').addEventListener('change', function(event) {
    const file = event.target.files[0];
    if (file) {
        const url = URL.createObjectURL(file);
        const videoPlayer = document.getElementById('videoPlayer');
        videoPlayer.src = url;
    }
});
