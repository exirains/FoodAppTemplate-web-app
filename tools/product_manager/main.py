import sys
import argparse
import random
from datetime import date
from supabase_client import supabase
from image_uploader import upload_product_image

def list_products():
    response = supabase.table("products").select("id, name, price, available, tag").execute()
    products = response.data
    print(f"{'ID':<36} | {'Name':<20} | {'Price':<6} | {'Available':<10} | {'Tag'}")
    print("-" * 90)
    for p in products:
        tag = p.get('tag') or "None"
        print(f"{p['id']:<36} | {p['name']:<20} | {p['price']:<6} | {p['available']:<10} | {tag}")

def get_tag_selection():
    tags = ["Popular", "New", "Traditional", "Recommended", "Seasonal", "No Tag"]
    print("\nSelect a product tag:")
    for i, tag in enumerate(tags, 1):
        print(f"{i}. {tag}")
    
    while True:
        try:
            choice = int(input("Choice (1-6): "))
            if 1 <= choice <= 6:
                selected = tags[choice - 1]
                return None if selected == "No Tag" else selected
            print("Invalid choice. Please select 1-6.")
        except ValueError:
            print("Please enter a number.")

def add_product():
    print("Adding a new product. Please provide the details:")
    name = input("Product name: ")
    description = input("Description: ")
    
    price = float(input("Price: "))
    category_id = input("Category UUID: ")
    
    tag = get_tag_selection()
    
    prep_time = int(input("Preparation time (mins) [20]: ") or 20)
    calories = int(input("Calories (kcal) [250]: ") or 250)
    is_organic = input("Is it organic? (y/n): ").lower() == 'y'
    
    image_path = input("Image path: ")
    available = input("Available? (y/n): ").lower() == 'y'

    print("Uploading image...")
    image_url = upload_product_image(image_path, "bread") # Defaulting to bread category for bucket path
    if not image_url:
        print("Failed to upload image. Aborting.")
        return

    print("Creating product record...")
    data = {
        "name": name,
        "description": description,
        "price": price,
        "category_id": category_id,
        "image_url": image_url,
        "available": available,
        "tag": tag,
        "prep_time": prep_time,
        "calories": calories,
        "is_organic": is_organic
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
    print(f"Updating product: {p['name']}")
    
    name = input(f"New name [{p['name']}]: ") or p['name']
    description = input(f"New description [{p['description']}]: ") or p['description']
    price = input(f"New price [{p['price']}]: ")
    price = float(price) if price else p['price']
    
    prep_time = input(f"New prep time [{p.get('prep_time', 20)}]: ")
    prep_time = int(prep_time) if prep_time else p.get('prep_time', 20)

    calories = input(f"New calories [{p.get('calories', 250)}]: ")
    calories = int(calories) if calories else p.get('calories', 250)

    is_organic = input(f"Is organic? (y/n) [{ 'y' if p.get('is_organic') else 'n'}]: ").lower()
    is_organic = is_organic == 'y' if is_organic else p.get('is_organic', False)

    change_tag = input(f"Change tag? (current: {p.get('tag') or 'None'}) (y/n): ").lower() == 'y'
    tag = get_tag_selection() if change_tag else p.get('tag')
    
    available = input(f"Available (y/n) [{ 'y' if p['available'] else 'n'}]: ").lower()
    available = available == 'y' if available else p['available']

    data = {
        "name": name,
        "description": description,
        "price": price,
        "prep_time": prep_time,
        "calories": calories,
        "is_organic": is_organic,
        "available": available,
        "tag": tag
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

    popular_parser = subparsers.add_parser("popular", help="Manage Popular Today products")
    popular_parser.add_argument("action", choices=["list", "generate", "clear"], help="Action to perform")

    args = parser.parse_args()

    if args.command == "list":
        list_products()
    elif args.command == "add":
        add_product()
    elif args.command == "update":
        update_product(args.id)
    elif args.command == "delete":
        delete_product(args.id)
    elif args.command == "popular":
        if args.action == "list":
            res = supabase.table("popular_today").select("display_date, products(name)").execute()
            for p in res.data:
                print(f"{p['display_date']} | {p['products']['name']}")
        elif args.action == "generate":
            print("Generating popular products...")
            import random
            from datetime import date
            res = supabase.table("products").select("id").eq("available", True).execute()
            if not res.data:
                print("No products available.")
            else:
                selection = random.sample(res.data, min(3, len(res.data)))
                today = str(date.today())
                data = [{"product_id": p['id'], "display_date": today} for p in selection]
                supabase.table("popular_today").upsert(data).execute()
                print(f"Generated {len(selection)} popular products for {today}.")
        elif args.action == "clear":
            supabase.table("popular_today").delete().neq("id", "00000000-0000-0000-0000-000000000000").execute()
            print("Cleared popular today table.")
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
