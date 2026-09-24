# Legend Heroes — Chapter 1: Ashen Crest

JRPG pixel art bergaya HD-2D untuk Android & iOS (Flutter + Flame). Spec lengkap: `Legend Heroes Chapter 1 — Game Spec & Plan.md`.

## Jalankan

```sh
flutter pub get
flutter test        # unit test battle engine & data
flutter run         # device / simulator, landscape
```

## Struktur

- `lib/domain/` — logika game Dart murni (battle engine, stats, skill), tanpa Flame.
- `lib/data/` — loader `assets/data/*.json`.
- `lib/game/` — dunia Flame (overworld, scene battle).
- `lib/presentation/` — overlay Flutter + Bloc (kontrol, HUD battle).
- `asset/` — sumber sprite asli; salinan yang dipakai game ada di `assets/images/`.
