# Tuto Recuperation Musique Mureka

Ce tuto permet de recuperer la bonne piste publiee depuis une page `song-detail` Mureka, sans prendre les anciens liens `test`.

## Principe

1. Ouvrir la page publique `song-detail`.
2. Lire `window.__INITIAL_STATE__` dans le HTML.
3. Recuperer `storeDetailStoreData.info.mp3_url`.
4. Construire l'URL finale:
   - `https://static-cos.mureka.ai/` + `mp3_url`
5. Telecharger le fichier MP3.

## Exemple (ton cas)

- Page:
  - `https://www.mureka.ai/song-detail/132975377317891?from=mine_generation_song`
- `mp3_url` trouve:
  - `cos-prod/song/basic-audio/20260413/music_132975373516804_4YKjE9xrB4ZD5FW39oVVS9_rutqen.mp3`
- URL finale:
  - `https://static-cos.mureka.ai/cos-prod/song/basic-audio/20260413/music_132975373516804_4YKjE9xrB4ZD5FW39oVVS9_rutqen.mp3`

## Commandes

```bash
cd /home/billy/Work/Ingrid
source .venv/bin/activate
python - <<'PY'
import json, requests
url='https://www.mureka.ai/song-detail/132975377317891?from=mine_generation_song'
html=requests.get(url,timeout=30).text
start=html.find('window.__INITIAL_STATE__ =')
sub=html[start:]
end=sub.find('</script>')
chunk=sub[:end].split('=',1)[1].strip()
if chunk.endswith(';'):
    chunk=chunk[:-1]
obj=json.loads(chunk)
info=((obj.get('storeDetailStoreData') or {}).get('info') or {})
mp3=info.get('mp3_url') or ((info.get('song') or {}).get('mp3_url'))
print('https://static-cos.mureka.ai/' + mp3.lstrip('/'))
PY
```

Puis telecharger:

```bash
cd /home/billy/Work/Ingrid/downloads
curl -fL -A "Mozilla/5.0" -e "https://www.mureka.ai/" \
  -o "ma_musique.mp3" "URL_GENEREE"
```

## Notes

- Si `mp3_url` commence par `cos-prod/...`, l'hote le plus fiable est `static-cos.mureka.ai`.
- Les URLs `test.melodio.ai` peuvent etre des liens de test ou proteges et retourner `403`.
- Cette methode marche bien pour les pages publiees avec donnees publiques presentes dans `window.__INITIAL_STATE__`.
