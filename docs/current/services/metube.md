# MeTube

YouTube downloader running as LXC 203 on Bolex (`192.168.2.52`).

## Downloads

- Audio/video downloads go to `/music/Downloads` inside the LXC.
- LXC bind-mount maps that to `tank-media/multimedia/Music/Downloads` on the host.
- A post-processor enriches MP3s with Deezer metadata and moves them to `/music/Temp_To_include` for manual review.

## Restart

```bash
pct stop 203 && pct start 203
```

## Related

- [Benthem Wiki — MeTube MP3 Pipeline](https://wiki.benthem.es/concepts/metube-mp3-pipeline)
- [Benthem Wiki — Music Discovery Pipeline](https://wiki.benthem.es/concepts/music-discovery-pipeline)
