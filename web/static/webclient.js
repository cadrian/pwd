function copy() {
    var source = document.getElementById('copytext');
    var target = document.getElementById('holdtext');
    target.innerText = source.innerText;
    var copied = target.createTextRange();
    copied.execCommand("Copy");
}

function submit_passform(path) {
    var form = document.getElementById('passform');
    form.action = path;
    form.submit();
}
