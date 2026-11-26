const fs = require('fs');
const path = require('path');

function copyRecursiveSync(src, dest) {
  const exists = fs.existsSync(src);
  const stats = exists && fs.statSync(src);
  const isDirectory = exists && stats.isDirectory();
  if (isDirectory) {
    if (!fs.existsSync(dest)) {
      fs.mkdirSync(dest, { recursive: true });
    }
    fs.readdirSync(src).forEach((childItemName) => {
      copyRecursiveSync(path.join(src, childItemName), path.join(dest, childItemName));
    });
  } else {
    fs.copyFileSync(src, dest);
  }
}

console.log('Copying build/web to docs/ and public/...');
if (fs.existsSync('web/sw.js')) {
  fs.copyFileSync('web/sw.js', 'build/web/sw.js');
  fs.copyFileSync('web/sw.js', 'build/web/flutter_service_worker.js');
}
copyRecursiveSync('build/web', 'docs');
copyRecursiveSync('build/web', 'public');
if (fs.existsSync('web/sw.js')) {
  fs.copyFileSync('web/sw.js', 'docs/sw.js');
  fs.copyFileSync('web/sw.js', 'public/sw.js');
  fs.copyFileSync('web/sw.js', 'docs/flutter_service_worker.js');
  fs.copyFileSync('web/sw.js', 'public/flutter_service_worker.js');
}

if (fs.existsSync('web/index.html')) {
  fs.copyFileSync('web/index.html', 'build/web/index.html');
  fs.copyFileSync('web/index.html', 'docs/index.html');
  fs.copyFileSync('web/index.html', 'public/index.html');
}

console.log('Web deployment files updated successfully!');
