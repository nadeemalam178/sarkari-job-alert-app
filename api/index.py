import os
import sys

# Add parent directory to path so imports work smoothly in Vercel serverless
parent_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if parent_dir not in sys.path:
    sys.path.insert(0, parent_dir)

from app import app

# Vercel serverless entry point
app.debug = False
