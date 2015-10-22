function submit_passform(path) {
    var form = document.getElementById('passform');
    form.action = path;
    form.submit();
}

function setClipboard() {
    var clipboard = new Clipboard('.clip');

    clipboard.on('success', function(e) {
        console.info('Action:', e.action);
        console.info('Text:', e.text);
        console.info('Trigger:', e.trigger);

        e.clearSelection();

        alert("copied.");
    });

    clipboard.on('error', function(e) {
        console.error('Action:', e.action);
        console.error('Trigger:', e.trigger);
        alert("copy failed!");
    });
}
