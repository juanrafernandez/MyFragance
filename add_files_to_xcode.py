#!/usr/bin/env python3
"""
Script to add Gift Recommendation files to PerfBeta.xcodeproj
"""
import uuid
import re
import os

PROJECT_FILE = "/Users/juanrafernandez/Documents/GitHub/MyFragance/PerfBeta.xcodeproj/project.pbxproj"

# Files to add with their groups
FILES_TO_ADD = [
    {
        "path": "PerfBeta/Models/GiftRecommendation/GiftQuestion.swift",
        "group": "Models",  # Add directly to Models group for now
        "parent_group": None
    },
    {
        "path": "PerfBeta/Models/GiftRecommendation/GiftResponse.swift",
        "group": "Models",  # Add directly to Models group for now
        "parent_group": None
    },
    {
        "path": "PerfBeta/Models/GiftRecommendation/GiftProfile.swift",
        "group": "Models",  # Add directly to Models group for now
        "parent_group": None
    },
    {
        "path": "PerfBeta/Services/GiftQuestionService.swift",
        "group": "Services",
        "parent_group": None
    },
    {
        "path": "PerfBeta/ViewModels/GiftRecommendationViewModel.swift",
        "group": "ViewModels",
        "parent_group": None
    },
]

def generate_uuid():
    """Generate a 24-character hex UUID similar to Xcode's format"""
    return uuid.uuid4().hex[:24].upper()

def read_project_file():
    """Read the project.pbxproj file"""
    with open(PROJECT_FILE, 'r') as f:
        return f.read()

def write_project_file(content):
    """Write the project.pbxproj file"""
    with open(PROJECT_FILE, 'w') as f:
        f.write(content)

def find_group_uuid(content, group_name):
    """Find the UUID of a group by name"""
    # Look for pattern: UUID /* GroupName */ = {
    pattern = r'([A-F0-9]{24})\s*/\*\s*' + re.escape(group_name) + r'\s*\*/\s*=\s*\{'
    match = re.search(pattern, content)
    if match:
        return match.group(1)
    return None

def find_sources_build_phase_uuid(content):
    """Find the UUID of the PBXSourcesBuildPhase"""
    pattern = r'([A-F0-9]{24})\s*/\*\s*Sources\s*\*/\s*=\s*\{[^}]*isa\s*=\s*PBXSourcesBuildPhase'
    match = re.search(pattern, content, re.DOTALL)
    if match:
        return match.group(1)
    return None

def add_file_to_project(content, file_info):
    """Add a file to the Xcode project"""
    filename = os.path.basename(file_info["path"])
    relative_path = file_info["path"]

    # For files going into existing groups:
    # - Services and ViewModels: just use filename
    # - Models: need to include GiftRecommendation/ subfolder
    if file_info["group"] == "Models" and "GiftRecommendation" in relative_path:
        file_path_for_ref = f"GiftRecommendation/{filename}"
    else:
        file_path_for_ref = filename

    # Generate UUIDs
    file_ref_uuid = generate_uuid()
    build_file_uuid = generate_uuid()

    print(f"Adding {filename}...")
    print(f"  Actual file location: {relative_path}")
    print(f"  Xcode ref path: {file_path_for_ref}")
    print(f"  To group: {file_info['group']}")
    print(f"  FileRef UUID: {file_ref_uuid}")
    print(f"  BuildFile UUID: {build_file_uuid}")

    # 1. Add PBXBuildFile entry
    pbx_build_file_section_pattern = r'(\/\* Begin PBXBuildFile section \*\/)'
    build_file_entry = f'''\t\t{build_file_uuid} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {filename} */; }};
'''
    content = re.sub(pbx_build_file_section_pattern,
                     r'\1\n' + build_file_entry,
                     content)

    # 2. Add PBXFileReference entry
    pbx_file_ref_section_pattern = r'(\/\* Begin PBXFileReference section \*\/)'
    file_ref_entry = f'''\t\t{file_ref_uuid} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_path_for_ref}; sourceTree = "<group>"; }};
'''
    content = re.sub(pbx_file_ref_section_pattern,
                     r'\1\n' + file_ref_entry,
                     content)

    # 3. Add to PBXGroup (find the group and add file reference)
    group_uuid = find_group_uuid(content, file_info["group"])
    if group_uuid:
        print(f"  Found group '{file_info['group']}': {group_uuid}")
        # Find the children array for this group and add our file
        group_pattern = rf'{group_uuid}\s*/\*\s*{re.escape(file_info["group"])}\s*\*/\s*=\s*\{{[^}}]*children\s*=\s*\(((?:[^()]|\([^()]*\))*)\)'

        def add_to_children(match):
            children_content = match.group(1)
            new_child = f'\t\t\t\t{file_ref_uuid} /* {filename} */,\n'
            return match.group(0).replace(children_content, children_content + new_child)

        content = re.sub(group_pattern, add_to_children, content, flags=re.DOTALL)
    else:
        print(f"  Warning: Group '{file_info['group']}' not found!")

    # 4. Add to PBXSourcesBuildPhase
    sources_uuid = find_sources_build_phase_uuid(content)
    if sources_uuid:
        print(f"  Found Sources build phase: {sources_uuid}")
        sources_pattern = rf'{sources_uuid}\s*/\*\s*Sources\s*\*/\s*=\s*\{{[^}}]*files\s*=\s*\(((?:[^()]|\([^()]*\))*)\)'

        def add_to_sources(match):
            files_content = match.group(1)
            new_file = f'\t\t\t\t{build_file_uuid} /* {filename} in Sources */,\n'
            return match.group(0).replace(files_content, files_content + new_file)

        content = re.sub(sources_pattern, add_to_sources, content, flags=re.DOTALL)
    else:
        print(f"  Warning: Sources build phase not found!")

    return content

def main():
    print("=" * 60)
    print("Adding Gift Recommendation files to Xcode project")
    print("=" * 60)
    print()

    # Read project file
    print("Reading project file...")
    content = read_project_file()
    print(f"Project file size: {len(content)} bytes")
    print()

    # Backup project file
    backup_file = PROJECT_FILE + ".backup"
    print(f"Creating backup: {backup_file}")
    with open(backup_file, 'w') as f:
        f.write(content)
    print()

    # Add each file
    for file_info in FILES_TO_ADD:
        content = add_file_to_project(content, file_info)
        print()

    # Write modified project file
    print("Writing modified project file...")
    write_project_file(content)
    print("Done!")
    print()
    print("=" * 60)
    print("Files successfully added to Xcode project!")
    print("Please open Xcode to verify the changes.")
    print("If something went wrong, restore from backup:")
    print(f"  cp {backup_file} {PROJECT_FILE}")
    print("=" * 60)

if __name__ == "__main__":
    main()
