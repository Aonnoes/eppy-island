# Eppy Island

> a simple farming game

- **Live demo:** https://aonnoes.github.io/eppy-island/
- **Demo video:** `docs/demo.mp4` <!-- TODO: at the finals submission -->
- **Course:** Applications Development and Emerging Technologies (6ADET), Holy Angel University
- **Author:** Aaron Noel

---

<!-- TODO: at the end of week 2 -->
## Screenshots

Put two or three real screenshots at phone size in `docs/assets/`, then replace
this paragraph with them:

```markdown
| Home | Detail | Add |
| --- | --- | --- |
| ![Home](docs/assets/screen-home.png) | ![Detail](docs/assets/screen-detail.png) | ![Add](docs/assets/screen-add.png) |
```

## What you do

Three to five bullets. What can a user actually do?

- farm for crops
- tell your mother you love her
- play rock-paper-scissors

<!-- TODO: at the end of week 2 -->
## Built with Flame

| | |
| --- | --- |
| Framework | Flutter (Dart) |
| State | `setState` / provider / riverpod (say which) |
| Storage | shared_preferences / Hive / Drift / Firebase / Supabase / other |
| Other packages | list the ones that matter, with a word on why |

<!-- TODO: at the end of week 2, it should run on any device -->
## Running it yourself, on the web

```bash
flutter pub get
flutter run -d web-server --web-port 8080
```

Then open http://localhost:8080. Requires Flutter (run `flutter --version` and
put yours here).

<!-- TODO: at the end of week 2 -->
### Environment variables

This project reads its configuration from a `.env` file that is **not** in the
repository. Copy `.env.example`, fill in your own values, and never commit the
result.

| Variable | What it is | Where to get one |
| --- | --- | --- |
| `EXAMPLE_API_KEY` | ... | ... |


## Privacy and secret

- What personal data this app stores, if any, and where it goes.
  - The app doesn't store any personal information and it doesn't have any way to.
- Where the secrets live
  - The secrets live on my local computer and none of them leave it.
- Confirm that all sample data, screenshots and the video contain
  - <!-- TODO: at the final submission -->

## Project documentation

<!-- TODO: at the end of week 2 -->
| Document | |
| --- | --- |
| [Proposal](docs/01-proposal.md) | the problem, the users, the scope |
| [Mockup and wireframes](docs/02-mockup.md) | what it looks like, and the screen flow |
| [Design system](docs/03-design-system.md) | colors, type, spacing, components |
| [Weekly reports](docs/04-weekly-reports.md) | what happened each week |
| [Demo video](docs/05-demo-video.md) | the recording and what it shows |
| [Start here](START-HERE.md) | how this repo works (delete once you have read it) |
| [Security and privacy](docs/06-security-and-privacy.md) | the checklist, filled in |

## Status and what is next

Nothing works at the moment. It's just a map with an animated character in the middle. Will work on:
- Player controls
- Camera
- Shop mechanics
- Inventory
- Main gameplay: the dungeon

## Credits

- **Sprout Lands** — a simple cute 16-bit pixel art farming asset pack with animals and farming, along with farming GUI asset pack with icons, buttons, character expresions, and many other tiles in pastel colors.
  - Source: [Asset Pack](https://cupnooble.itch.io/sprout-lands-asset-pack) and [UI Expansion](https://cupnooble.itch.io/sprout-lands-ui-pack)
  - Artist: [Cup Nooble](https://itch.io/profile/cupnooble)

- Packages: see `pubspec.yaml`

<!-- TODO: at the end of week 2 -->
## AI use

If you used AI tools while building this, say so in a sentence or two and say
where. Honest disclosure is the standard in this course and increasingly outside
it.

## License

The source code of this project is licensed under the MIT License.
See the [LICENSE](LICENSE) file for details.

Third-party assets, including artwork, music, sound effects, fonts, and
other resources, are subject to their respective licenses and are not
necessarily covered by the MIT License.
