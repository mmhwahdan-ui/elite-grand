# Elite Grand - Local Preview Server
$port = 8080
$folder = "$PSScriptRoot\build\web"

if (-not (Test-Path $folder)) {
    Write-Host "Build folder not found. Please run 'flutter build web' first." -ForegroundColor Red
    exit 1
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "   تطبيق إيليت جراند للتمريض المنزلي يعمل محلياً الآن!    " -ForegroundColor Cyan
Write-Host "   الرابط: http://localhost:$port                        " -ForegroundColor Yellow
Write-Host "   اضغط Ctrl+C لإيقاف السيرفر                            " -ForegroundColor Gray
Write-Host "==========================================================" -ForegroundColor Green

Start-Process "http://localhost:$port"

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $path = $request.Url.LocalPath.TrimStart('/')
        if ([string]::IsNullOrEmpty($path)) { $path = "index.html" }
        $filePath = Join-Path $folder $path

        if (Test-Path $filePath -PathType Leaf) {
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $mime = switch ($ext) {
                ".html" { "text/html; charset=utf-8" }
                ".js"   { "application/javascript" }
                ".json" { "application/json" }
                ".css"  { "text/css" }
                ".png"  { "image/png" }
                ".wasm" { "application/wasm" }
                default { "application/octet-stream" }
            }
            $response.ContentType = $mime
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            # Fallback for SPA routing to index.html
            $indexPath = Join-Path $folder "index.html"
            $bytes = [System.IO.File]::ReadAllBytes($indexPath)
            $response.ContentType = "text/html; charset=utf-8"
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        }
        $response.Close()
    }
} finally {
    $listener.Stop()
}
