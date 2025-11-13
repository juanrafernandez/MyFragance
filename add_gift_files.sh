#!/bin/bash

# Script to add Gift Recommendation files to Xcode project
# This will be done by opening Xcode programmatically

PROJECT_DIR="/Users/juanrafernandez/Documents/GitHub/MyFragance"
PROJECT_FILE="$PROJECT_DIR/PerfBeta.xcodeproj"

# Files to add
FILES=(
    "PerfBeta/Models/GiftRecommendation/GiftQuestion.swift"
    "PerfBeta/Models/GiftRecommendation/GiftResponse.swift"
    "PerfBeta/Models/GiftRecommendation/GiftProfile.swift"
    "PerfBeta/Services/GiftQuestionService.swift"
    "PerfBeta/ViewModels/GiftRecommendationViewModel.swift"
)

echo "Adding Gift Recommendation files to Xcode project..."
echo ""

# Generate UUIDs for the files
for file in "${FILES[@]}"; do
    if [ -f "$PROJECT_DIR/$file" ]; then
        echo "✓ Found: $file"
    else
        echo "✗ Missing: $file"
        exit 1
    fi
done

echo ""
echo "All files found. You need to add them to Xcode manually or use the following approach:"
echo ""
echo "Option 1: Manual (Recommended)"
echo "  1. Open PerfBeta.xcodeproj in Xcode"
echo "  2. Right-click on the appropriate groups:"
echo "     - Models/GiftRecommendation/ → Add GiftQuestion.swift, GiftResponse.swift, GiftProfile.swift"
echo "     - Services/ → Add GiftQuestionService.swift"
echo "     - ViewModels/ → Add GiftRecommendationViewModel.swift"
echo "  3. Ensure 'Add to targets: PerfBeta' is checked"
echo ""
echo "Option 2: Use xcodeproj gem (if installed)"
echo "  gem install xcodeproj"
echo "  # Then run a Ruby script to add files"
echo ""

# Alternative: Try to use xed to open in Xcode
read -p "Would you like to open the project in Xcode now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "$PROJECT_FILE"
    echo "Xcode opened. Please add the files manually as described above."
fi
