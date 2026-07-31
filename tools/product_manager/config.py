import os
from dotenv import load_dotenv

# Load .env file
load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    print("Error: Missing Supabase configuration.")
    print("Create a .env file based on .env.example with SUPABASE_URL and SUPABASE_SERVICE_KEY.")
    exit(1)
