# Share Extension setup (photos + voice memos)

ZON receives shared content from the iOS share sheet (Photos → check-ins,
Voice Memos → timeline voice notes) through a **custom App Group + method
channel** bridge — no third-party share plugin.

## Prerequisite ⚠️

**App Groups requires a paid Apple Developer Program membership.** On a free
personal team Xcode cannot register the group, so the whole share flow stays
inert until you enroll — the same wall that blocks remote push. The Dart +
native code is complete and will light up the moment the App Group is valid.

## How it works

```
Voice Memos app  ──share──▶  Share Extension (ShareViewController.swift)
                               • copies recordings into the App Group container
                                 (group.app.getzon.zon/shared_voice/…)
                               • stores metadata [{path, recordedAt}] in
                                 UserDefaults(suiteName: group…) key "sharedVoiceMemos"
                               • opens app.getzon://shared-voice
                                        │
main app (AppDelegate.swift)  ◀─────────┘
   • reads & clears the UserDefaults key, forwards over MethodChannel
     "app.getzon.zon/sharing" → method "sharedVoiceMemos"
     (or buffers for the "getPendingVoiceMemos" poll on a cold launch)
                                        │
Flutter (SharedVoiceService) ◀──────────┘
   • _ZonAppState routes to /voice-import with the List<SharedVoiceMemo>
   • VoiceImportScreen: transcribe on-device → review → add as timeline notes
```

Photos use the identical path with key `sharedPhotosMetadata`, host
`shared-photos`, method `sharedPhotos`.

## Files already scaffolded (in this repo)

- `ios/ShareExtension/ShareViewController.swift` — handles image **and** audio attachments
- `ios/ShareExtension/Info.plist` — activation rule for `public.image` OR `public.audio`
- `ios/ShareExtension/ShareExtension.entitlements` — App Group
- `ios/Runner/Runner.entitlements` — App Group (main app)
- `ios/Runner/AppDelegate.swift` — reads the container, forwards both channels
- Main `Info.plist` already registers the `app.getzon` URL scheme

## Manual Xcode steps (cannot be scripted)

1. **Add the target:** File ▸ New ▸ Target ▸ *Share Extension*. Name it
   `ShareExtension`. Delete the auto-generated `ShareViewController.swift`,
   `MainInterface.storyboard`, and `Info.plist`, then add the three files from
   `ios/ShareExtension/` to the new target. (Remove the
   `NSExtensionMainStoryboard` key if Xcode added one — this extension is
   code-only via `NSExtensionPrincipalClass`.)
2. **App Group on both targets:** Runner and ShareExtension ▸ Signing &
   Capabilities ▸ + App Groups ▸ `group.app.getzon.zon`. Confirm each target's
   `CODE_SIGN_ENTITLEMENTS` points at the entitlements file above.
3. **Deployment target:** set the extension's iOS deployment target ≤ the
   Runner's.
4. No Podfile changes needed — the extension uses only system frameworks
   (`AVFoundation`, `ImageIO`), no Flutter plugins.

## Verify

Share a recording from Voice Memos → ZON. The app should foreground into the
import screen with the transcript filled in. If it doesn't foreground but the
memo still appears next time you open ZON, the URL-scheme hop failed but the
`applicationDidBecomeActive` fallback caught it — that's expected resilience.



Xcode Setup (manual, one-time)

Open ios/Runner.xcworkspace in Xcode, then follow these steps exactly.

1. Add the ShareExtension target

- File → New → Target…
- Choose Share Extension (under Application Extension)
- Set:
  - Product Name: ShareExtension
  - Language: Swift
  - Team: your Apple Developer account
  - Bundle Identifier: app.getzon.zon.ShareExtension
- Click Finish → when asked "Activate 'ShareExtension' scheme?" click Cancel (keep Runner active)

2. Replace the generated files with ours

Xcode will have created placeholder ShareViewController.swift and Info.plist inside a new ShareExtension group in the project. Our versions already exist on disk at ios/ShareExtension/. Do this:

- In the Project Navigator, delete the Xcode-generated files from the ShareExtension group (choose Move to Trash for the .swift and .plist, but Remove Reference only for any auto-created .entitlements)
- Then drag the existing files from Finder into the ShareExtension group in Xcode:
  - ios/ShareExtension/ShareViewController.swift
  - ios/ShareExtension/Info.plist
  - ios/ShareExtension/ShareExtension.entitlements
- When adding, make sure Add to targets: ShareExtension is checked (not Runner)

3. Set the entitlements file on both targets

Runner target:

- Select the Runner project → Runner target → Build Settings
- Search Code Signing Entitlements
- Set value to: Runner/Runner.entitlements

ShareExtension target:

- Select the Runner project → ShareExtension target → Build Settings
- Search Code Signing Entitlements
- Set value to: ShareExtension/ShareExtension.entitlements

4. Add App Group capability (both targets)

For Runner target → Signing & Capabilities → + Capability → App Groups
→ Add group.app.getzon.zon

For ShareExtension target → same → same group ID group.app.getzon.zon

5. Set the ShareExtension bundle ID in the target's General tab

ShareExtension target → General → Bundle Identifier → app.getzon.zon.ShareExtension

6. Build and test

Build (⌘B). Share a photo from Photos.app → choose ZON from the share sheet → the app opens to the inspection screen.

---
