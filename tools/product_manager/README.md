# Babka Product Management CLI Tool (v1.0.0)

Internal tool for managing the Babka bakery catalog in Supabase.

## Setup

1. **Install Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```


## Commands

### List All Products
```bash
python main.py list
```

### Add a New Product
```bash
python main.py add
```
- Interactive prompt will ask for localized names/descriptions, price, category, and local image path.
- Images are automatically uploaded to the `product-images` bucket.

### Update a Product
```bash
python main.py update <PRODUCT_UUID>
```

### Delete a Product
```bash
python main.py delete <PRODUCT_UUID>
```

## Troubleshooting

### ModuleNotFoundError: No module named 'supabase'
If you see this error despite running `pip install`, it means your terminal is using a different Python executable than your Pip. Use the following command to force installation into your active Python environment:
```bash
python -m pip install -r requirements.txt
```

### Authentication Error
Ensure your `.env` has the correct `SUPABASE_SERVICE_KEY` (formatted as `sb_secret_...`). This tool requires admin privileges to manage products and storage.

