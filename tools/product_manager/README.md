# Sangak Product Management CLI Tool (v1.0.0)

Internal tool for managing the Sangak bakery catalog in Supabase.

## Setup

1. **Install Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure Environment**:
   - Copy `.env.example` to `.env`.
   - Add your `SUPABASE_URL`.
   - Add your `SUPABASE_SERVICE_KEY` (formatted as `sb_secret_...`).

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

## Security Note
This tool uses the Supabase Service Role Key which bypasses Row Level Security (RLS). **Never** commit your `.env` file or share your service key.
