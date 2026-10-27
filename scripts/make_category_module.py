# -*- coding: utf-8 -*-
"""
Helper to create and validate a category module with exactly 300 items (100 L1, 100 L2, 100 L3).
"""

import os
import re

def create_cat_file(output_path, cat_id, prefix, l1_items, l2_items, l3_items):
    assert len(l1_items) == 100, f"L1 for {cat_id} has {len(l1_items)}, expected 100"
    assert len(l2_items) == 100, f"L2 for {cat_id} has {len(l2_items)}, expected 100"
    assert len(l3_items) == 100, f"L3 for {cat_id} has {len(l3_items)}, expected 100"

    all_q_texts = set()
    all_f_texts = set()

    for lvl, items in [(1, l1_items), (2, l2_items), (3, l3_items)]:
        for idx, (q, f, tags) in enumerate(items):
            q_clean = q.strip()
            f_clean = f.strip()

            if len(q_clean) < 20:
                raise ValueError(f"[{cat_id} L{lvl} #{idx}] Question too short ({len(q_clean)}): {q_clean}")
            if len(f_clean) < 20:
                raise ValueError(f"[{cat_id} L{lvl} #{idx}] Follow-up too short ({len(f_clean)}): {f_clean}")

            if re.search(r'\(\d+\)', q_clean):
                raise ValueError(f"[{cat_id} L{lvl} #{idx}] Question has (number): {q_clean}")
            if re.search(r'\(\d+\)', f_clean):
                raise ValueError(f"[{cat_id} L{lvl} #{idx}] Follow-up has (number): {f_clean}")

            if q_clean in all_q_texts:
                raise ValueError(f"[{cat_id} L{lvl} #{idx}] Duplicate Q in module: {q_clean}")
            all_q_texts.add(q_clean)

            if f_clean in all_f_texts:
                raise ValueError(f"[{cat_id} L{lvl} #{idx}] Duplicate F in module: {f_clean}")
            all_f_texts.add(f_clean)

    # Write file
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as out:
        out.write("# -*- coding: utf-8 -*-\n")
        out.write(f'"""Self-contained module for {cat_id} (300 questions)"""\n\n')
        out.write("def get_questions():\n")
        out.write("    items = []\n\n")

        # Level 1
        out.write("    # Level 1 (100 questions)\n")
        out.write("    l1_data = [\n")
        for q, f, tags in l1_items:
            out.write(f"        ({repr(q)}, {repr(f)}, {repr(tags)}),\n")
        out.write("    ]\n")
        out.write("    for i, (q, f, t) in enumerate(l1_data, 1):\n")
        out.write(f'        items.append({{"id": f"{prefix}_l1_{{i:03d}}", "categoryId": "{cat_id}", "level": 1, "question": q, "followUp": f, "tags": t}})\n\n')

        # Level 2
        out.write("    # Level 2 (100 questions)\n")
        out.write("    l2_data = [\n")
        for q, f, tags in l2_items:
            out.write(f"        ({repr(q)}, {repr(f)}, {repr(tags)}),\n")
        out.write("    ]\n")
        out.write("    for i, (q, f, t) in enumerate(l2_data, 1):\n")
        out.write(f'        items.append({{"id": f"{prefix}_l2_{{i:03d}}", "categoryId": "{cat_id}", "level": 2, "question": q, "followUp": f, "tags": t}})\n\n')

        # Level 3
        out.write("    # Level 3 (100 questions)\n")
        out.write("    l3_data = [\n")
        for q, f, tags in l3_items:
            out.write(f"        ({repr(q)}, {repr(f)}, {repr(tags)}),\n")
        out.write("    ]\n")
        out.write("    for i, (q, f, t) in enumerate(l3_data, 1):\n")
        out.write(f'        items.append({{"id": f"{prefix}_l3_{{i:03d}}", "categoryId": "{cat_id}", "level": 3, "question": q, "followUp": f, "tags": t}})\n\n')

        out.write("    return items\n")

    print(f"✅ Generated {output_path} ({len(all_q_texts)} unique questions)")
