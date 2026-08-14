# CLIP embedding service (image + product name/specs)

## Run
```bash
docker compose -f docker-compose.clip.yml up -d --build
```

Health: `GET http://localhost:8088/health`

## API
- `POST /embed/image` — image only (search query)
- `POST /embed/text` — text only
- `POST /embed/multimodal` — fuse image + catalog text (index)

## Backend config
```json
"ImageEmbedding": {
  "Enabled": true,
  "AutoIndexOnCatalogChanges": true,
  "ClipServiceUrl": "http://localhost:8088",
  "EmbeddingDimensions": 512,
  "ClipImageWeight": 0.7,
  "ClipTextWeight": 0.3
},
"Qdrant": {
  "Collection": "product_images_clip",
  "VectorSize": 512,
  "MinScore": 0.22
}
```

After deploy: `POST /api/admin/products/reindex-image-vectors`
