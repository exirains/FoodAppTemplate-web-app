import sys
import argparse
from supabase_client import supabase
from image_uploader import upload_product_image

def list_products():
    response = supabase.table("products").select("id, name_en, price, is_available").execute()
    products = response.data
    print(f"{'ID':<36} | {'Name (EN)':<20} | {'Price':<6} | {'Available'}")
    print("-" * 75)
    for p in products:
        print(f"{p['id']:<36} | {p['name_en']:<20} | {p['price']:<6} | {p['is_available']}")

def add_product():
    print("Adding a new product. Please provide the details:")
    name_en = input("Product name (English): ")
    name_tr = input("Product name (Turkish): ")
    name_fa = input("Product name (Persian): ")

    desc_en = input("Description (English): ")
    desc_tr = input("Description (Turkish): ")
    desc_fa = input("Description (Persian): ")

    price = float(input("Price: "))
    category = input("Category (e.g., bread, desserts): ")
    image_path = input("Image path: ")
    available = input("Available? (y/n): ").lower() == 'y'

    print("Uploading image...")
    image_url = upload_product_image(image_path, category)
    if not image_url:
        print("Failed to upload image. Aborting.")
        return

    print("Creating product record...")
    data = {
        "name_en": name_en,
        "name_tr": name_tr,
        "name_fa": name_fa,
        "description_en": desc_en,
        "description_tr": desc_tr,
        "description_fa": desc_fa,
        "price": price,
        "category": category,
        "image_url": image_url,
        "is_available": available
    }

    try:
        response = supabase.table("products").insert(data).execute()
        print(f"✓ Product created successfully! ID: {response.data[0]['id']}")
    except Exception as e:
        print(f"Error creating product: {e}")

def update_product(product_id):
    # Fetch existing data first
    res = supabase.table("products").select("*").eq("id", product_id).execute()
    if not res.data:
        print(f"Error: Product with ID {product_id} not found.")
        return

    p = res.data[0]
    print(f"Updating product: {p['name_en']}")

    name_en = input(f"New name (EN) [{p['name_en']}]: ") or p['name_en']
    price = input(f"New price [{p['price']}]: ")
    price = float(price) if price else p['price']
    available = input(f"Available (y/n) [{ 'y' if p['is_available'] else 'n'}]: ").lower()
    available = available == 'y' if available else p['is_available']

    data = {
        "name_en": name_en,
        "price": price,
        "is_available": available
    }

    try:
        supabase.table("products").update(data).eq("id", product_id).execute()
        print("✓ Product updated successfully!")
    except Exception as e:
        print(f"Error updating product: {e}")

def delete_product(product_id):
    confirm = input(f"Are you sure you want to delete product {product_id}? (y/n): ")
    if confirm.lower() == 'y':
        try:
            supabase.table("products").delete().eq("id", product_id).execute()
            print("✓ Product deleted successfully.")
        except Exception as e:
            print(f"Error deleting product: {e}")
    else:
        print("Delete aborted.")

def main():
    parser = argparse.ArgumentParser(description="Sangak Product Management CLI")
    subparsers = parser.add_subparsers(dest="command")

    subparsers.add_parser("list", help="List all products")
    subparsers.add_parser("add", help="Add a new product")

    update_parser = subparsers.add_parser("update", help="Update a product")
    update_parser.add_argument("id", help="The UUID of the product to update")

    delete_parser = subparsers.add_parser("delete", help="Delete a product")
    delete_parser.add_argument("id", help="The UUID of the product to delete")

    args = parser.parse_args()

    if args.command == "list":
        list_products()
    elif args.command == "add":
        add_product()
    elif args.command == "update":
        update_product(args.id)
    elif args.command == "delete":
        delete_product(args.id)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
