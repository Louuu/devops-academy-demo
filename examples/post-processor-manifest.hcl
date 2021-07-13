post-processor "manifest" {
    output = "manifest.json"
    strip_path = true
}

post-processor "shell-local" {
    inline = ["cp manifest.json ./remote/storage/manifests/example/manifest.json"]
}
