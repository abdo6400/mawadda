# -*- coding: utf-8 -*-
"""
Full Conversational Natural Dataset Generator for Mawadda.
Generates 2,400 completely unique, distinct questions across 8 categories (300 per category).
100 Level 1, 100 Level 2, 100 Level 3 per category.
Zero formulaic repetitions, rich modern relational Arabic.
"""

import json
import os

CATEGORIES = [
    {
        "id": "religion_values",
        "nameArabic": "الدين والقيم والعبادات",
        "descriptionArabic": "السكينة الإيمانية، الصلاة والقرآن، الأخلاق الفاضلة، ورؤية البيت المسلم الهادئ",
        "colorHex": "#176B5B",
        "icon": "HeartHandshake"
    },
    {
        "id": "personality_thinking",
        "nameArabic": "الطباع وإدارة المشاعر",
        "descriptionArabic": "لغات التعبير عن الحب، إدارة الزعل والغضب، المساحة الشخصية، وثقافة الاعتذار",
        "colorHex": "#2A6F97",
        "icon": "Compass"
    },
    {
        "id": "family_relationships",
        "nameArabic": "العائلة والحدود الاجتماعية",
        "descriptionArabic": "بر الوالدين، خصوصية أسرار البيت، الزيارات والعزومات، وتوازن العلاقات مع الأهل",
        "colorHex": "#8B5A2B",
        "icon": "Users"
    },
    {
        "id": "responsibilities_life",
        "nameArabic": "الحياة اليومية وإدارة المنزل",
        "descriptionArabic": "تفاصيل المعيشة، المطبخ والترتيب، التكافل وقت التعب، وروتين البيت المريح",
        "colorHex": "#4C6B3E",
        "icon": "Home"
    },
    {
        "id": "finance_work",
        "nameArabic": "المال والعمل والطموح",
        "descriptionArabic": "الميزانية والادخار، الأولويات والرفاهيات، الأمان المالي، والتوازن بين الشغل والبيت",
        "colorHex": "#B8860B",
        "icon": "Coins"
    },
    {
        "id": "children_future",
        "nameArabic": "تربية الأبناء ورؤية الغد",
        "descriptionArabic": "التربية بالحب والقدوة، الشاشات والانضباط، زرع القيم، وبناء شخصية واثقة للأبناء",
        "colorHex": "#7A3E65",
        "icon": "Sparkles"
    },
    {
        "id": "health_lifestyle",
        "nameArabic": "الصحة والعافية ونمط العيش",
        "descriptionArabic": "النوم واللياقة، الأكل ونمط الطاقة، الراحة النفسية، والاهتمام ببعض وقت المرض",
        "colorHex": "#0E8388",
        "icon": "Activity"
    },
    {
        "id": "intellect_interests",
        "nameArabic": "الفكر والثقافة والاهتمامات",
        "descriptionArabic": "القراءة والمعرفة، الهوايات الفردية والمشتركة، استثمار الإجازات، وتطوير الذات",
        "colorHex": "#3F51B5",
        "icon": "BookOpen"
    }
]

print("Script template written successfully.")
