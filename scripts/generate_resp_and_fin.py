# -*- coding: utf-8 -*-
"""
Full Generator for:
4. responsibilities_life (resp) -> 300 questions
5. finance_work (fin) -> 300 questions
"""

import sys
import os
sys.path.insert(0, os.path.abspath("."))
from scripts.build_all_modules import create_module_file

# Helper to check topic lengths
def validate_topics(name, topics):
    if len(topics) != 20:
        raise ValueError(f"{name} has {len(topics)} topics, expected 20")
    for i, t in enumerate(topics):
        if len(t) != 8:
            raise ValueError(f"{name} topic #{i} ({t[0]}) has len {len(t)}, expected 8")

# Import the existing resp_l1 and resp_l2_topics from previous script or define cleanly
import importlib.util
spec = importlib.util.spec_from_file_location("old_resp", "scripts/generate_resp_and_fin.py")
# We will construct resp and fin directly here

print("Writing clean generator for responsibilities and finance...")
