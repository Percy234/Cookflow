import re
import os

os.chdir('d:/MobileApp/cookflow')

with open('lib/screens/recipe_editor_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace AppColors
content = content.replace('AppColors.surfaceElevated', 'context.colors.surfaceElevated')
content = content.replace('AppColors.primary', 'context.colors.primary')
content = content.replace('AppColors.divider', 'context.colors.divider')
content = content.replace('AppColors.textHint', 'context.colors.textHint')
content = content.replace('AppColors.textPrimary', 'context.colors.textPrimary')
content = content.replace('AppColors.textSecondary', 'context.colors.textSecondary')
content = content.replace('AppColors.surface', 'context.colors.surface')
content = content.replace('AppColors.background', 'context.colors.background')
content = content.replace('AppColors.error', 'context.colors.error')

# Replace AppTextStyles
content = re.sub(r'AppTextStyles\.([a-zA-Z0-9_]+)', r'context.textTheme.\1!', content)
# Fix context.textTheme.foo!(.copyWith) -> context.textTheme.foo!.copyWith (already correct)
content = re.sub(r'context\.textTheme\.([a-zA-Z0-9_]+)!(?!\.copyWith)', r'context.textTheme.\1', content)

# Fix Colors.white defaults
content = content.replace('_colorDot(null, Colors.white)', '_colorDot(null, context.colors.textPrimary)')
content = content.replace(': Colors.white;', ': context.colors.background;')
content = content.replace('color: Colors.white,', 'color: context.colors.surface,')

# Fix const issues where context.colors is used
lines = content.split('\n')
for i in range(len(lines)):
    if ('context.colors' in lines[i] or 'context.textTheme' in lines[i]) and 'const ' in lines[i]:
        lines[i] = lines[i].replace('const ', '')

content = '\n'.join(lines)

with open('lib/screens/recipe_editor_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
