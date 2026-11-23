# Lightroom Classic Bulk Snapshot Creator Plugin

**Free and open source.** No account, no license key, no trial limit, no watermark.

Create a Develop snapshot for **every selected photo in one batch** instead of one photo at a time. Lightroom Classic has no built-in bulk snapshot command; this plug-in adds one.

<h2 align="center">
  <a href="https://github.com/leocb/lightroom-classic-bulk-snapshot-creator-plugin/releases/latest/download/LRC-Snapshot.lrplugin.zip">⬇️ Download the free plugin</a>
</h2>

<p align="center">
  <strong>Free forever · Works in bulk · Lightroom Classic 4+</strong>
</p>

## Why this plugin

| Manual Lightroom | This plug-in |
| --- | --- |
| Create one snapshot at a time | Create snapshots for the whole selection at once |
| Repeat the same name for every photo | Use tokens such as `{filename}` and `{date}` |
| Easy to miss photos in a large selection | One progress run and a clear summary |
| No batch naming | Live preview and a full token reference |

## Features

- **Bulk by design** — selects every photo in the current selection and creates a snapshot for each one.
- **Free and open source** — the full Lua source is in this repository.
- **Token-based names** — `{filename}`, `{date}`, `{capture_date}`, `{camera}`, `{sequence}`, and more.
- **Live preview** — see the expanded snapshot name before committing.
- **Duplicate control** — skip existing names by default, or update them in place.
- **Progress and summary** — see created, skipped, duplicate, video, and failed counts.
- **Remembers your template** — the last name pattern and replace setting are reused.

## Install

1. Download `LRC-Snapshot.lrplugin.zip` using the download link above.
2. Unzip it. You should have a folder named `LRC Snapshot.lrplugin`.
3. In Lightroom Classic, open **File > Plug-in Manager**.
4. Click **Add**, select `LRC Snapshot.lrplugin`, and click **Done**.
5. Select one or more photos in the Library or Develop module.
6. Run **File > Plug-in Extras > Create Snapshots for Selected Photos...**
   (also available under **Library > Plug-in Extras**).

Snapshots appear in the **Snapshots** panel on the left side of the Develop module.

## The dialog

- **Snapshot name** — free text plus tokens. The preview shows the expanded name for the first selected photo.
- **Replace an existing snapshot with the same name** — off by default. When off, photos that already have a snapshot with the expanded name are skipped. When on, the existing snapshot is updated in place.
- **Token Reference** — opens the full token list. Your current name and settings are kept when you close the reference.

The last name template and replace setting are remembered.

## Tokens

Tokens are expanded separately for each photo. Unknown tokens are left untouched, which makes typos visible in the preview.

### Photo

| Token | Value |
| --- | --- |
| `{filename}` | File name with extension |
| `{filename_noext}` | File name without extension |
| `{ext}` | File extension |
| `{folder}` | Parent folder name |
| `{camera}` | Camera model |
| `{lens}` | Lens |
| `{iso}` | ISO, e.g. `ISO 400` |
| `{aperture}` | Aperture, e.g. `f/2.8` |
| `{shutter}` | Shutter speed, e.g. `1/250s` |
| `{focal_length}` | Focal length, e.g. `50mm` |
| `{rating}` | Star rating, or `unrated` |
| `{label}` | Color label name, or `none` |

### Dates and selection

| Token | Value |
| --- | --- |
| `{capture_date}` | Capture date, e.g. `2026-11-22` |
| `{capture_time}` | Capture time, e.g. `22-10-05` |
| `{capture_datetime}` | Capture date and time |
| `{date}` | Today's date |
| `{time}` | Current time |
| `{datetime}` | Current date and time |
| `{sequence}` | Position in the selection, starting at 1 |
| `{total}` | Number of selected photos |

Use `{{` and `}}` for literal braces.

### Examples

| Template | Result for a photo |
| --- | --- |
| `{filename} - {date}` | `IMG_1234.CR2 - 2026-11-22` |
| `{filename_noext} {capture_datetime}` | `IMG_1234 2026-11-22_22-10-05` |
| `Edit {sequence} of {total}` | `Edit 3 of 12` |

## Notes

- Snapshots are created from each photo's current Develop settings, so run the command from the Develop module (or after making the edits you want to capture).
- Videos are skipped because Develop snapshots apply to photos.
- The plug-in requires Lightroom 4 or later (all Lightroom Classic versions; SDK 4.0).
- Tested by validating Lua syntax and the token/batch flow with a local harness.

## Download

- **Latest release:** [Download the free plugin](https://github.com/leocb/lightroom-classic-bulk-snapshot-creator-plugin/releases/latest/download/LRC-Snapshot.lrplugin.zip)
- **All releases:** [github.com/leocb/lightroom-classic-bulk-snapshot-creator-plugin/releases](https://github.com/leocb/lightroom-classic-bulk-snapshot-creator-plugin/releases)

## License

MIT. See [LICENSE](LICENSE).
