# -*- coding: utf-8 -*-
"""
Builder for the remaining 7 Mawadda categories:
- personality_thinking
- family_relationships
- responsibilities_life
- finance_work
- children_future
- health_lifestyle
- intellect_interests

Each category produces exactly 300 natural, conversational, diverse Arabic questions (100 L1, 100 L2, 100 L3).
All questions and follow-ups are 100% unique, conversational, warm, and meaningful.
"""

import json
import os

def create_module_file(filename, cat_id, prefix, l1_specs, l2_specs, l3_specs):
    """
    Generates a python file that exports get_questions() with 300 items (100 L1, 100 L2, 100 L3).
    Each level has 20 topics x 5 distinct conversational forms = 100 questions.
    """
    lines = []
    lines.append("# -*- coding: utf-8 -*-")
    lines.append(f'"""Module for category {cat_id}"""')
    lines.append("")
    lines.append("def get_questions():")
    lines.append("    items = []")
    lines.append("")
    
    # Generate Level 1
    lines.append("    # LEVEL 1 (100 questions)")
    lines.append("    l1_data = [")
    for topic, desc, tags, (q1, f1), (q2, f2), (q3, f3), (q4, f4), (q5, f5) in l1_specs:
        lines.append(f"        # {topic}")
        lines.append(f'        ({repr(q1)}, {repr(f1)}, {repr(tags)}),')
        lines.append(f'        ({repr(q2)}, {repr(f2)}, {repr(tags)}),')
        lines.append(f'        ({repr(q3)}, {repr(f3)}, {repr(tags)}),')
        lines.append(f'        ({repr(q4)}, {repr(f4)}, {repr(tags)}),')
        lines.append(f'        ({repr(q5)}, {repr(f5)}, {repr(tags)}),')
    lines.append("    ]")
    lines.append("    for i, (q, f, t) in enumerate(l1_data, 1):")
    lines.append(f'        items.append({{"id": f"{prefix}_l1_{{i:03d}}", "categoryId": "{cat_id}", "level": 1, "question": q, "followUp": f, "tags": t}})')
    lines.append("")

    # Generate Level 2
    lines.append("    # LEVEL 2 (100 questions)")
    lines.append("    l2_data = [")
    for topic, desc, tags, (q1, f1), (q2, f2), (q3, f3), (q4, f4), (q5, f5) in l2_specs:
        lines.append(f"        # {topic}")
        lines.append(f'        ({repr(q1)}, {repr(f1)}, {repr(tags)}),')
        lines.append(f'        ({repr(q2)}, {repr(f2)}, {repr(tags)}),')
        lines.append(f'        ({repr(q3)}, {repr(f3)}, {repr(tags)}),')
        lines.append(f'        ({repr(q4)}, {repr(f4)}, {repr(tags)}),')
        lines.append(f'        ({repr(q5)}, {repr(f5)}, {repr(tags)}),')
    lines.append("    ]")
    lines.append("    for i, (q, f, t) in enumerate(l2_data, 1):")
    lines.append(f'        items.append({{"id": f"{prefix}_l2_{{i:03d}}", "categoryId": "{cat_id}", "level": 2, "question": q, "followUp": f, "tags": t}})')
    lines.append("")

    # Generate Level 3
    lines.append("    # LEVEL 3 (100 questions)")
    lines.append("    l3_data = [")
    for topic, desc, tags, (q1, f1), (q2, f2), (q3, f3), (q4, f4), (q5, f5) in l3_specs:
        lines.append(f"        # {topic}")
        lines.append(f'        ({repr(q1)}, {repr(f1)}, {repr(tags)}),')
        lines.append(f'        ({repr(q2)}, {repr(f2)}, {repr(tags)}),')
        lines.append(f'        ({repr(q3)}, {repr(f3)}, {repr(tags)}),')
        lines.append(f'        ({repr(q4)}, {repr(f4)}, {repr(tags)}),')
        lines.append(f'        ({repr(q5)}, {repr(f5)}, {repr(tags)}),')
    lines.append("    ]")
    lines.append("    for i, (q, f, t) in enumerate(l3_data, 1):")
    lines.append(f'        items.append({{"id": f"{prefix}_l3_{{i:03d}}", "categoryId": "{cat_id}", "level": 3, "question": q, "followUp": f, "tags": t}})')
    lines.append("")
    lines.append("    return items")

    with open(filename, 'w', encoding='utf-8') as f:
        f.write("\n".join(lines) + "\n")
    print(f"Generated {filename} successfully.")

print("Builder generator helper ready.")
