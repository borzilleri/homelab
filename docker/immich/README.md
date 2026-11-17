# API Key Permissions

## Homepage

[source](https://gethomepage.dev/widgets/services/immich/)

```yaml
# Server
- server.statistics
```

## Immich Power Tools

[source](https://github.com/immich-power-tools/immich-power-tools)

```yaml
# All
```

## Immich Kiosk

[source](https://docs.immichkiosk.app/installation/#api-key-permissions)

```yaml
# Asset
- asset.read
- asset.update
- asset.view

# Album
- album.create
- album.read
- album.update
- album.statistics
# Album Assets
- albumAsset.create
- albumAsset.delete

# Archive (used for "show_archived")
- archive.read

# Face (used for smart-zoom)
- face.read

# Memories
- memory.read

# Person
- person.read
- person.statistics

# Server (used for the /about page)
- server.about

# Tag
- tag.create
- tag.read
- tag.update
- tag.asset

# User (used to see asset onwership)
- user.read
```

# Photos Immich Sync

[source](https://github.com/borzilleri/photos-immich-sync)

```yaml
# Asset
- asset.read
- asset.update
- asset.delete
- asset.upload
- asset.copy

# Album
- album.create
- album.read
- album.update
- album.delete

# AlbumAsset
- albumAsset.create
- albumAsset.delete

# Stack
- stack.create

# Tag
- tag.create
- tag.read
- tag.update
- tag.delete
- tag.asset
```