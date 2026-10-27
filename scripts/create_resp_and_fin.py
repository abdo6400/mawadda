# -*- coding: utf-8 -*-
"""
Generates scripts/dataset_modules/cat_responsibilities.py and scripts/dataset_modules/cat_finance.py
Each with 300 unique conversational questions (100 L1, 100 L2, 100 L3).
"""

import os
import json

def generate_category_module(filepath, cat_id, prefix, l1_tuples, l2_tuples, l3_tuples):
    """
    Writes a self-contained python file for the category.
    l1_tuples, l2_tuples, l3_tuples are lists of (question, follow_up, tags).
    Each must have exactly 100 items.
    """
    assert len(l1_tuples) == 100, f"Expected 100 for L1, got {len(l1_tuples)}"
    assert len(l2_tuples) == 100, f"Expected 100 for L2, got {len(l2_tuples)}"
    assert len(l3_tuples) == 100, f"Expected 100 for L3, got {len(l3_tuples)}"

    lines = []
    lines.append("# -*- coding: utf-8 -*-")
    lines.append(f'"""Self-contained module for {cat_id} (300 questions)"""')
    lines.append("")
    lines.append("def get_questions():")
    lines.append("    items = []")
    lines.append("")
    
    # L1
    lines.append("    # Level 1 (100 questions)")
    lines.append("    l1_data = [")
    for q, f, tags in l1_tuples:
        lines.append(f"        ({repr(q)}, {repr(f)}, {repr(tags)}),")
    lines.append("    ]")
    lines.append("    for i, (q, f, t) in enumerate(l1_data, 1):")
    lines.append(f'        items.append({{"id": f"{prefix}_l1_{{i:03d}}", "categoryId": "{cat_id}", "level": 1, "question": q, "followUp": f, "tags": t}})')
    lines.append("")

    # L2
    lines.append("    # Level 2 (100 questions)")
    lines.append("    l2_data = [")
    for q, f, tags in l2_tuples:
        lines.append(f"        ({repr(q)}, {repr(f)}, {repr(tags)}),")
    lines.append("    ]")
    lines.append("    for i, (q, f, t) in enumerate(l2_data, 1):")
    lines.append(f'        items.append({{"id": f"{prefix}_l2_{{i:03d}}", "categoryId": "{cat_id}", "level": 2, "question": q, "followUp": f, "tags": t}})')
    lines.append("")

    # L3
    lines.append("    # Level 3 (100 questions)")
    lines.append("    l3_data = [")
    for q, f, tags in l3_tuples:
        lines.append(f"        ({repr(q)}, {repr(f)}, {repr(tags)}),")
    lines.append("    ]")
    lines.append("    for i, (q, f, t) in enumerate(l3_data, 1):")
    lines.append(f'        items.append({{"id": f"{prefix}_l3_{{i:03d}}", "categoryId": "{cat_id}", "level": 3, "question": q, "followUp": f, "tags": t}})')
    lines.append("")
    lines.append("    return items")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write("\n".join(lines) + "\n")
    print(f"Successfully generated {filepath} (300 questions).")

print("Generator helper function ready.")
