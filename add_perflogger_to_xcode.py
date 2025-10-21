#!/usr/bin/env python3
"""
Script to add PerformanceLogger.swift to the Xcode project file.
"""

import re
import uuid

def generate_uuid():
    """Generate a 24-character hex ID similar to Xcode's format"""
    return uuid.uuid4().hex[:24].upper()

def add_file_to_project():
    pbxproj_path = "PerfBeta.xcodeproj/project.pbxproj"

    # Read the file
    with open(pbxproj_path, 'r') as f:
        content = f.read()

    # Generate UUIDs
    perflogger_ref_id = generate_uuid()
    perflogger_build_id = generate_uuid()

    # 1. Add PBXBuildFile entry
    build_file_section_pattern = r'(/\* Begin PBXBuildFile section \*/\n)'
    build_file_entry = f"""\\1\t\t{perflogger_build_id} /* PerformanceLogger.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {perflogger_ref_id} /* PerformanceLogger.swift */; }};
"""
    content = re.sub(build_file_section_pattern, build_file_entry, content, count=1)

    # 2. Add PBXFileReference entry
    file_ref_section_pattern = r'(/\* Begin PBXFileReference section \*/\n)'
    file_ref_entry = f"""\\1\t\t{perflogger_ref_id} /* PerformanceLogger.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PerformanceLogger.swift; sourceTree = "<group>"; }};
"""
    content = re.sub(file_ref_section_pattern, file_ref_entry, content, count=1)

    # 3. Add to Utils group (find the Utils group and add the file)
    utils_group_pattern = r'(457D142B2CF682D4004C297A /\* Utils \*/ = \{[^}]*children = \([^)]*)'

    # Check if we can find the Utils group
    if re.search(utils_group_pattern, content):
        # Add PerformanceLogger to the end of the children list
        utils_group_replacement = f"\\1\n\t\t\t\t{perflogger_ref_id} /* PerformanceLogger.swift */,"
        content = re.sub(utils_group_pattern, utils_group_replacement, content, count=1)
    else:
        print("⚠️  Could not find Utils group pattern")
        return False

    # 4. Add to PBXSourcesBuildPhase
    sources_phase_pattern = r'(457D140F2CF68253004C297A /\* Sources \*/ = \{[^}]*files = \([^)]*)'
    source_entry = f"\\1\n\t\t\t\t{perflogger_build_id} /* PerformanceLogger.swift in Sources */,"
    content = re.sub(sources_phase_pattern, source_entry, content, count=1, flags=re.DOTALL)

    # Write back
    with open(pbxproj_path, 'w') as f:
        f.write(content)

    print("✅ Successfully added PerformanceLogger.swift to Xcode project!")
    print(f"   - File reference ID: {perflogger_ref_id}")
    print(f"   - Build file ID: {perflogger_build_id}")
    return True

if __name__ == "__main__":
    add_file_to_project()
