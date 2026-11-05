# Clothing-only AI test fixture

`black_tshirt.jpg` is **FairtradeCertifiedCottonTShirt.jpg** by
**Raysonho @ Open Grid Scheduler / Grid Engine**, May 17, 2008.
The creator released it into the public domain worldwide (PD-self).

- Source: https://commons.wikimedia.org/wiki/File:FairtradeCertifiedCottonTShirt.jpg
- Original: https://upload.wikimedia.org/wikipedia/commons/a/a5/FairtradeCertifiedCottonTShirt.jpg

The photo is a close-up of an unworn black T-shirt and its product tag. It lives
under `android/app/src/debug/assets/flutter_assets/backend_test/`, so Android
debug tests can load it through Flutter's asset bundle without an entry in the
app's `pubspec.yaml`. Release builds do not package the fixture. The sample
closet has its own separate assets.
