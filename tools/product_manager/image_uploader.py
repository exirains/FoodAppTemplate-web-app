import os
import logging
from supabase_client import supabase

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def upload_product_image(file_path: str, category: str):
    """Uploads an image to the product-images bucket and returns the public URL."""
    if not os.path.exists(file_path):
        error_msg = f"File not found: {file_path}"
        logger.error(error_msg)
        print(f"Error: {error_msg}")
        return None

    file_name = os.path.basename(file_path)
    bucket_path = f"{category}/{file_name}"

    try:
        with open(file_path, 'rb') as f:
            # Upload image
            res = supabase.storage.from_("product-images").upload(
                path=bucket_path,
                file=f,
                file_options={"content-type": "image/jpeg"}
            )

        # Get public URL
        url_res = supabase.storage.from_("product-images").get_public_url(bucket_path)
        return url_res
    except IOError as e:
        error_msg = f"Failed to read file: {file_path} - {str(e)}"
        logger.error(error_msg)
        print(f"Error: {error_msg}")
        return None
    except Exception as e:
        error_msg = f"Failed to upload image to Supabase: {str(e)}"
        logger.error(error_msg)
        print(f"Error: {error_msg}")
        return None
