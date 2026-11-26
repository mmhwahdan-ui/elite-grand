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
}
copyRecursiveSync('build/web', 'docs');
copyRecursiveSync('build/web', 'public');
if (fs.existsSync('web/sw.js')) {
  fs.copyFileSync('web/sw.js', 'docs/sw.js');
  fs.copyFileSync('web/sw.js', 'public/sw.js');
}

const ts = Date.now();
['docs/index.html', 'public/index.html'].forEach(filePath => {
  if (fs.existsSync(filePath)) {
    let content = fs.readFileSync(filePath, 'utf8');
    content = content.replace(/flutter_bootstrap\.js(\?v=\d+)?/g, `flutter_bootstrap.js?v=${ts}`);
    fs.writeFileSync(filePath, content, 'utf8');
    console.log(`Updated cache buster in ${filePath}`);
  }
});

console.log('Web deployment files updated successfully!');
