var NwBuilder = require('nw-builder');
var fs = require('fs');
var archiver = require('archiver');

var PLATFORMS = ['win32', 'linux64', 'win64', 'osx64'];
var VERSION = JSON.parse(fs.readFileSync('package.json')).version;

function directoryToZipFile(sourceDirectory, targetZipFile) {
  var output = fs.createWriteStream(targetZipFile);
  var archive = archiver('zip');
  output.on('close', function () {
      console.log('Zipped '+sourceDirectory+' to '+targetZipFile+' ('+archive.pointer()+'B)');
  });
  archive.on('error', function(err){
    throw err;
  });
  archive.pipe(output);
  archive.bulk([
    { expand: true, cwd: sourceDirectory, src: ['**'] }
  ]);
  archive.finalize();
}

function runNwBuilder() {
  var nw = new NwBuilder({
    files: 'fuckr/**',
    platforms: PLATFORMS,
    version: '0.20.2',
    appName: 'Fuckr',
    appVersion: VERSION,
    winIco: /^win/.test(process.platform) ? 'icons/win.ico' : null,
    macIcns: 'icons/mac.icns',
    flavor: 'normal',
    zip: false
  });
  nw.on('log', console.log.bind(console));
  return nw.build();
}

function runAppDmg() {
  var appdmg = require('appdmg');
  if(fs.existsSync('releases/Fuckr.dmg')) fs.unlink('releases/Fuckr.dmg');
  var ee = appdmg({
    target: 'releases/Fuckr.dmg',
    basepath: './',
    specification: {
      "title": "Fuckr",
      "icon": "icons/mac.icns",
      "background": "dmgbg.png",
      "icon-size": 128,
      "contents": [
        { "x": 452, "y": 220, "type": "link", "path": "/Applications" },
        { "x": 145, "y": 220, "type": "file", "path": "./build/fuckr/osx64/Fuckr.app" }
      ]
    }
  });
  ee.on('progress', console.info);
  ee.on('error', console.error);
}

runNwBuilder().then(function() {
  if(!fs.existsSync('releases')) fs.mkdirSync('releases');
  PLATFORMS.forEach(function(platform) {
    directoryToZipFile('build/Fuckr/' + platform, 'releases/Fuckr-' + platform + '.zip')
  });

  if(process.platform === 'darwin') runAppDmg();
}).catch(console.error.bind(console));
