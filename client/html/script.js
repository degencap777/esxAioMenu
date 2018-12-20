$(function() {
    // Listen for NUI Messages.
    window.addEventListener('message', function(event) {
        var audioPlayer = null;
        // Check for playSound transaction
        if (event.data.transactionType == "playSound") {	
            if (audioPlayer != null) {
				audioPlayer.pause();
            }
            audioPlayer = new Audio("./sounds/" + event.data.transactionFile + ".ogg");
            audioPlayer.volume = event.data.transactionVolume;
            audioPlayer.play();
		}
    });
});