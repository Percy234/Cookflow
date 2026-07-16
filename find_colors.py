import re

with open('lib/screens/recipe_editor_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

output = []
for i, line in enumerate(lines):
    if 'Colors.' in line or 'AppColors.' in line or 'AppTextStyles.' in line:
        output.append(f"{i+1}: {line.strip()}")

with open('color_lines.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(output))
