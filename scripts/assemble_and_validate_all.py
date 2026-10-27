# -*- coding: utf-8 -*-
"""
Assembler and Validator for Mawadda 2,400 Dataset
Combines all 8 modular category files:
- cat_religion.py
- cat_personality.py
- cat_family.py
- cat_responsibilities.py
- cat_finance.py
- cat_children.py
- cat_health.py
- cat_intellect.py

Outputs:
- assets/questions/questions.json
- src/data/questionsData.ts
"""

import sys
import os
import json
import re

sys.path.insert(0, os.path.abspath("."))

from scripts.dataset_modules.cat_religion import get_questions as get_religion
from scripts.dataset_modules.cat_personality import get_questions as get_personality
from scripts.dataset_modules.cat_family import get_questions as get_family
from scripts.dataset_modules.cat_responsibilities import get_questions as get_responsibilities
from scripts.dataset_modules.cat_finance import get_questions as get_finance
from scripts.dataset_modules.cat_children import get_questions as get_children
from scripts.dataset_modules.cat_health import get_questions as get_health
from scripts.dataset_modules.cat_intellect import get_questions as get_intellect

CATEGORIES = [
    {
        "id": "religion_values",
        "nameArabic": "الدين والقيم والعبادات",
        "descriptionArabic": "المبادئ الإيمانية، الالتزام بالفرائض والسنن، الأخلاق الفاضلة، ورؤية البيت المسلم",
        "colorHex": "#176B5B",
        "icon": "HeartHandshake"
    },
    {
        "id": "personality_thinking",
        "nameArabic": "الطباع وإدارة المشاعر",
        "descriptionArabic": "السمات الشخصية، إدارة الغضب والضغوط، أسلوب التعبير، وحل الخلافات برقي",
        "colorHex": "#2A6F97",
        "icon": "Compass"
    },
    {
        "id": "family_relationships",
        "nameArabic": "العائلة والحدود الاجتماعية",
        "descriptionArabic": "بر الوالدين، صلة الأرحام، حفظ خصوصية البيت الزوجي، والتعامل الحكيم مع الأهل",
        "colorHex": "#8B5A2B",
        "icon": "Users"
    },
    {
        "id": "responsibilities_life",
        "nameArabic": "الحياة اليومية وإدارة المنزل",
        "descriptionArabic": "إدارة البيت، التكافل والتعاون، روتين العناية، وتناغم تفاصيل المعيشة المشتركة",
        "colorHex": "#4C6B3E",
        "icon": "Home"
    },
    {
        "id": "finance_work",
        "nameArabic": "المال والعمل والطموح",
        "descriptionArabic": "الميزانية والادخار، الذمة المالية، أولويات الإنفاق، والتوازن بين الطموح المهني والأسرة",
        "colorHex": "#B8860B",
        "icon": "Coins"
    },
    {
        "id": "children_future",
        "nameArabic": "تربية الأبناء ورؤية الغد",
        "descriptionArabic": "التربية الإسلامية السوية، توقيت الإنجاب، الأهداف المشتركة، ورسم ملامح المستقبل",
        "colorHex": "#7A3E65",
        "icon": "Sparkles"
    },
    {
        "id": "health_lifestyle",
        "nameArabic": "الصحة والعافية ونمط العيش",
        "descriptionArabic": "العادات الصحية، اللياقة والنشاط، التوازن النفسي، والتعامل مع الإرهاق والضغوط",
        "colorHex": "#C05621",
        "icon": "Activity"
    },
    {
        "id": "intellect_interests",
        "nameArabic": "الفكر والثقافة والاهتمامات",
        "descriptionArabic": "القراءة والمعرفة، الهوايات الفردية والمشتركة، استثمار الوقت، وتطوير الذات",
        "colorHex": "#4A5568",
        "icon": "BookOpen"
    }
]

def main():
    print("Gathering questions from all 8 modules...")
    modules = [
        ("religion_values", get_religion()),
        ("personality_thinking", get_personality()),
        ("family_relationships", get_family()),
        ("responsibilities_life", get_responsibilities()),
        ("finance_work", get_finance()),
        ("children_future", get_children()),
        ("health_lifestyle", get_health()),
        ("intellect_interests", get_intellect())
    ]

    all_questions = []
    seen_ids = set()
    seen_questions = set()
    seen_followups = set()

    for cat_id, questions in modules:
        if len(questions) != 300:
            raise ValueError(f"Module for {cat_id} returned {len(questions)} items, expected 300!")
        
        l1 = [q for q in questions if q["level"] == 1]
        l2 = [q for q in questions if q["level"] == 2]
        l3 = [q for q in questions if q["level"] == 3]

        if len(l1) != 100 or len(l2) != 100 or len(l3) != 100:
            raise ValueError(f"Category {cat_id} levels not balanced: L1={len(l1)}, L2={len(l2)}, L3={len(l3)}")

        for q in questions:
            qid = q["id"]
            qtext = q["question"].strip()
            qfollow = q["followUp"].strip()

            if qid in seen_ids:
                raise ValueError(f"Duplicate question ID: {qid}")
            seen_ids.add(qid)

            if qtext in seen_questions:
                raise ValueError(f"Duplicate question text: '{qtext}' in category {cat_id}")
            seen_questions.add(qtext)

            if qfollow in seen_followups:
                raise ValueError(f"Duplicate follow-up text: '{qfollow}' in category {cat_id}")
            seen_followups.add(qfollow)

            # Check index number
            if re.search(r'\(\d+\)', qtext):
                raise ValueError(f"Question text contains (number): {qtext}")
            if re.search(r'\(\d+\)', qfollow):
                raise ValueError(f"Follow-up contains (number): {qfollow}")

            if len(qtext) < 20:
                raise ValueError(f"Question text too short: {qtext}")
            if len(qfollow) < 20:
                raise ValueError(f"Follow-up text too short: {qfollow}")
            if not q.get("tags"):
                raise ValueError(f"Question missing tags: {qid}")

            all_questions.append(q)

    if len(all_questions) != 2400:
        raise ValueError(f"Total questions count is {len(all_questions)}, expected 2400!")

    print(f"Validation successful! Total questions: {len(all_questions)}")
    print(f"Unique IDs: {len(seen_ids)}")
    print(f"Unique Question Texts: {len(seen_questions)}")
    print(f"Unique Follow-ups: {len(seen_followups)}")

    data = {
        "categories": CATEGORIES,
        "questions": all_questions
    }

    # Write assets/questions/questions.json
    os.makedirs("assets/questions", exist_ok=True)
    with open("assets/questions/questions.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print("Wrote assets/questions/questions.json")

    # Write src/data/questionsData.ts
    ts_content = f"""// Generated dataset for Mawadda - 2,400 completely unique conversational questions
// 8 categories, 300 questions per category (100 L1, 100 L2, 100 L3)

export interface Question {{
  id: string;
  categoryId: string;
  level: number;
  question: string;
  followUp: string;
  tags: string[];
}}

export interface Category {{
  id: string;
  nameArabic: string;
  descriptionArabic: string;
  colorHex: string;
  icon: string;
}}

export interface MawaddaData {{
  categories: Category[];
  questions: Question[];
}}

export const MAWADDA_DATA: MawaddaData = {json.dumps(data, ensure_ascii=False, indent=2)};
"""
    with open("src/data/questionsData.ts", "w", encoding="utf-8") as f:
        f.write(ts_content)
    print("Wrote src/data/questionsData.ts")

if __name__ == "__main__":
    main()
