import os
from supabase_client import supabase

def upload_product_image(file_path: str, category: str):
    """Uploads an image to the product-images bucket and returns the public URL."""
    if not os.path.exists(file_path):
        print(f"Error: File {file_path} not found.")
        return None

    file_name = os.path.basename(file_path)
    # Target path in bucket: bread/sangak.jpg
    bucket_path = f"{category}/{file_name}"

    try:
        with open(file_path, 'rb') as f:
            # Upload image
            res = supabase.storage.from_("product-images").upload(
                path=bucket_path,
                file=f,
                file_options={"content-type": "image/jpeg"} # Basic assumption
            )

        # Get public URL
        url_res = supabase.storage.from_("product-images").get_public_url(bucket_path)
        return url_res
    except Exception as e:
        print(f"Error uploading image: {e}")
        return None
