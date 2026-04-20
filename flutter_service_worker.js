'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "5851bdb564e1a7cb99565322bab76727",
".git/config": "920a11de313bfb8d93d81f4a3a5b71b6",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/HEAD": "4cf2d64e44205fe628ddd534e1151b58",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "e405a37735a2808af9c13429816e36ee",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "dae9fcc2228cb8d6aa7c4fac97783aaa",
".git/logs/refs/heads/master": "dae9fcc2228cb8d6aa7c4fac97783aaa",
".git/objects/00/18f535545d5c93c727910d29fbaf4984b82599": "20d404aac5e2407dd1a288061657d43a",
".git/objects/05/a9058f513cce5faf1704e06e3c150688b0a01f": "e8d02f60cf87abd4c1de4b153dd696dc",
".git/objects/06/724dedbcd39ec4f6776fe77ebd279e45f03946": "d87a8dafd9221a591220a47060e458cd",
".git/objects/08/951b02106daa24ec5e35dd21a7a8e2fdf91781": "2ad00569826855e0c2b61f590d831d0e",
".git/objects/0d/32977ffe9788c29e5c747e468eeeaa2c4e591a": "a9bbf0c6d4dc1c44adc0f3c3728f1bd8",
".git/objects/0d/d20aed9339852db3f4624e43fae26ed20821ea": "52a635ade5f1d5f499a6475a419034ee",
".git/objects/13/e7d86c3e8c21e5ef3e1d67aec491b2529026c0": "7b812ffdc6adfe817dfd482bcbeda13a",
".git/objects/21/d317f8fa86ff3ad6e85a75870c7b498e21ce23": "b279f469ffc0c15bf5a2c69412c5bc31",
".git/objects/26/5c9a4f7bf1b7ccba2a2147503dcb3b86c05a47": "9bb1de997b1621b08a146b74af2f96f6",
".git/objects/27/a297abdda86a3cbc2d04f0036af1e62ae008c7": "51d74211c02d96c368704b99da4022d5",
".git/objects/2e/42c264a4482caefdd442ef43211d3491b40ce0": "afb61e76f9b8c4a79ae778c184b5fa9c",
".git/objects/34/b16bd0f93e550e8cbffc6f2b4c7b88986e2c91": "e57694810c586699d774232a6f1cf265",
".git/objects/36/d3f514b1954959636823e4e73565faf0cff96d": "1f6bd77272ad52d6acf9f212fb555a3a",
".git/objects/37/985676f2843b36165c78adfa1288a544a12abf": "1e41808d4a7a8e5f61ef5026a8fdf9db",
".git/objects/3c/76574db2b084a63124e5e09c077272f01cfe44": "2fd62d4b6e12e224da085b96261da68f",
".git/objects/40/f1694ba4c97cdfaaa99a6459feab9a24614586": "aca2ed34561ba1ba8fc7d7674cd50113",
".git/objects/42/b3551f9fb538165b768e4401a37431483190bd": "f88f14ea62e00299225f491c140ae272",
".git/objects/49/fba14ad0f999985af3781b87528cfbf333ef87": "2a89234e33f1ee5aa35a2fad0df769bf",
".git/objects/4c/b5676cdc9d62f38dbbcf24f1496353234bcd6f": "c7f5352f6c4c894b68e8724afa7dec5d",
".git/objects/63/6931bcaa0ab4c3ff63c22d54be8c048340177b": "8cc9c6021cbd64a862e0e47758619fb7",
".git/objects/66/524546a9caa737339b8c0bb649962d2c78fe4b": "6ccd15981bec5dcc2b878b7b85e88015",
".git/objects/67/87bf8ee6e97414e417f1af3a41f7bb99db798c": "24392f41d54aebd752239d437c89fbfa",
".git/objects/6d/5f0fdc7ccbdf7d01fc607eb818f81a0165627e": "2b2403c52cb620129b4bbc62f12abd57",
".git/objects/6f/78340ff83d4c6d766d77ebc6a90ea38099a58c": "5f511ef2d372897268f7bf7d451341c9",
".git/objects/73/7f149c855c9ccd61a5e24ce64783eaf921c709": "1d813736c393435d016c1bfc46a6a3a6",
".git/objects/74/fce7ebedfd2c5672db4da95384e96405f8ab30": "a254dbd92c883ac02f36a9e37a114f9e",
".git/objects/79/694a829d300fb0d662d4566bb0acea6b2c5697": "abffedacfad17af15c1f040fb6143716",
".git/objects/7e/6f673396a09e9c3e9e8ff584d194c65005632c": "fe101fcf7046ae27fd7dc0a22db61a7e",
".git/objects/84/485d40eed56d10bdc00eeab93c1d14bf0cb8cd": "ac688fd410a5780e8f750fd300ba5363",
".git/objects/84/95bf5377bf719e0dd72c3d717f065d2330e420": "790ad7048480f1f205fa5bd8886677b2",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/8c/59773bee8314a8ffb4431593d0fb49f52e34c6": "2eb993d30677573ffd0e58484cc6a514",
".git/objects/97/8a4d89de1d1e20408919ec3f54f9bba275d66f": "dbaa9c6711faa6123b43ef2573bc1457",
".git/objects/99/1c8979d168007b04f944492bb3d263764319ef": "c02590c7b7e8b8eada25f6c107e7ead2",
".git/objects/a6/13ad16b9fefbc12ffc7f76da6207da7d55a25e": "47b208d5fa14f41c5dd5009f4f0fc08f",
".git/objects/a9/38c2852615c8d28f005d2305cce9622e6c0bf6": "26cb976a5b84d658f223750dc17e2793",
".git/objects/ae/d200cdc0f63ae48bd2ea4fffce4b1baa6e5c7a": "400427f149c4a0905814f233a2fc56eb",
".git/objects/af/31ef4d98c006d9ada76f407195ad20570cc8e1": "a9d4d1360c77d67b4bb052383a3bdfd9",
".git/objects/b1/5ad935a6a00c2433c7fadad53602c1d0324365": "8f96f41fe1f2721c9e97d75caa004410",
".git/objects/b1/afd5429fbe3cc7a88b89f454006eb7b018849a": "e4c2e016668208ba57348269fcb46d7b",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/b9/f646b7ce5db79f55ec55a925984a264fa4be6f": "e36de810ef63798e4168b69c5efb08fd",
".git/objects/c1/ad8d06c3f20e102e874d3bf01d246d1dbb9584": "253382bdbb91739034c9b176a32d3ab3",
".git/objects/c3/e81f822689e3b8c05262eec63e4769e0dea74c": "8c6432dca0ea3fdc0d215dcc05d00a66",
".git/objects/c6/06caa16378473a4bb9e8807b6f43e69acf30ad": "ed187e1b169337b5fbbce611844136c6",
".git/objects/c6/d36c5f95008dcafd94c6ecb38330e2f45c5df0": "4881715f3202bb374ed9bb5e56494b10",
".git/objects/c9/53389a2ad7d6c75bb23643a6601a34d1d6b706": "e153c849b2ce6eeb747dfb2d0ed4c989",
".git/objects/c9/8d4347cae0bcb91a7874921c5eeb2355666a08": "e33d6faf391784e035e87dbd8ec9f553",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/d8/fe6292aa015b1e07d269224d7bcfd3bd56611f": "9661b631adfb4fe85bb02dafafaba93e",
".git/objects/e1/523e8fe17758448bfa6b103d877ba21f2c085c": "dd2f6322ce0d289dc9f2c2176f02b9d0",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/ec/361605e9e785c47c62dd46a67f9c352731226b": "d1eafaea77b21719d7c450bcf18236d6",
".git/objects/ec/d87d9a1020fe2c0ff19d15d67f9d3618d7d229": "4e2d86df9b42a144122931da7c35b558",
".git/objects/ee/3251b14302d2881d75f2012d4179c2eac154a9": "66441470a99391303a95a71aa9b88f50",
".git/objects/ef/e8b1f34895b70fb8da182ccfd8d244acd8ab8e": "845b98ff5ef48a51ae9e04d39a7c4ebc",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/f7/c63baa7402cb4864909e4d6b03049c23b307be": "cd59a78da35555a7dc4da00b49c1d7c6",
".git/objects/f8/2fc4fe965818540d936f7d4d75cfb9ed4efcb6": "179e6c9cebf76a8fe9beb9512b1672fb",
".git/refs/heads/master": "458b9bbf672624c8ce96033a646d4514",
"assets/AssetManifest.bin": "c51ff88ab5bfb42fbe432c8cc8ed8543",
"assets/AssetManifest.bin.json": "b0e015ae915bb04dd071a7bd13129772",
"assets/AssetManifest.json": "829ed864392076d6b87b3f7ca4f1f8a9",
"assets/FontManifest.json": "53f76a8f2ac6a1e94b9129063ae0e978",
"assets/fonts/MaterialIcons-Regular.otf": "161976c547f3a322a5c74914435bc9c7",
"assets/NOTICES": "d5e7b94093660834009fb5b813fb2b93",
"assets/packages/iconsax/lib/assets/fonts/iconsax.ttf": "071d77779414a409552e0584dcbfd03d",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "26eef3024dbc64886b7f48e1b6fb05cf",
"canvaskit/canvaskit.js.symbols": "efc2cd87d1ff6c586b7d4c7083063a40",
"canvaskit/canvaskit.wasm": "e7602c687313cfac5f495c5eac2fb324",
"canvaskit/chromium/canvaskit.js": "b7ba6d908089f706772b2007c37e6da4",
"canvaskit/chromium/canvaskit.js.symbols": "e115ddcfad5f5b98a90e389433606502",
"canvaskit/chromium/canvaskit.wasm": "ea5ab288728f7200f398f60089048b48",
"canvaskit/skwasm.js": "ac0f73826b925320a1e9b0d3fd7da61c",
"canvaskit/skwasm.js.symbols": "96263e00e3c9bd9cd878ead867c04f3c",
"canvaskit/skwasm.wasm": "828c26a0b1cc8eb1adacbdd0c5e8bcfa",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "4b2350e14c6650ba82871f60906437ea",
"flutter_bootstrap.js": "9b88c4cecc2ed529675bf223aaee13ee",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "76bf1b1b452d20b8535647c10375e402",
"/": "76bf1b1b452d20b8535647c10375e402",
"main.dart.js": "7daa1753c6fe2e0aa3042bd3e2631edb",
"manifest.json": "07eed66f3024a8debbbea93e2efa515d",
"version.json": "c2ee24c0ed0d75f3c5c0e0ce82b76979"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
