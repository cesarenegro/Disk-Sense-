//
//  HelpView.swift
//  DiskLense
//
//  Created by APPLE on 12/2/2026.
//


import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedSection = "Getting Started"
    
    let sections = [
        "Getting Started",
        "Smart Clean vs One-Click Clean",
        "Flash Clean",
        "App Uninstall",
        "Duplicate Files",
        "Large Files",
        "Startup Items",
        "Intelligence Tools",
        "Keyboard Shortcuts",
        "FAQ",
        "Safety & Privacy"
    ]
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(sections, id: \.self, selection: $selectedSection) { section in
                HStack {
                    Image(systemName: iconForSection(section))
                        .foregroundColor(colorForSection(section))
                        .frame(width: 20)
                    Text(section)
                        .font(.subheadline)
                }
                .padding(.vertical, 4)
            }
            .listStyle(.sidebar)
            .frame(minWidth: 220)
            .navigationTitle("Help & FAQ")
            
        } detail: {
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch selectedSection {
                    case "Getting Started":
                        GettingStartedView()
                    case "Smart Clean vs One-Click Clean":
                        SmartCleanVsOneClickView()
                    case "Flash Clean":
                        FlashCleanHelpView()
                    case "App Uninstall":
                        AppUninstallHelpView()
                    case "Duplicate Files":
                        DuplicatesHelpView()
                    case "Large Files":
                        LargeFilesHelpView()
                    case "Startup Items":
                        StartupHelpView()
                    case "Intelligence Tools":
                        IntelligenceToolsHelpView()
                    case "Keyboard Shortcuts":
                        KeyboardShortcutsView()
                    case "FAQ":
                        FAQView()
                    case "Safety & Privacy":
                        SafetyView()
                    default:
                        GettingStartedView()
                    }
                }
                .padding(32)
            }
        }
        .frame(width: 800, height: 600)
    }
    
    private func iconForSection(_ section: String) -> String {
        switch section {
        case "Getting Started": return "house.fill"
        case "Smart Clean vs One-Click Clean": return "wand.and.stars"
        case "Flash Clean": return "bolt.fill"
        case "App Uninstall": return "app.badge"
        case "Duplicate Files": return "doc.on.doc"
        case "Large Files": return "archivebox"
        case "Startup Items": return "power"
        case "Intelligence Tools": return "sparkles"
        case "Keyboard Shortcuts": return "keyboard"
        case "FAQ": return "questionmark.circle"
        case "Safety & Privacy": return "lock.shield"
        default: return "doc"
        }
    }
    
    private func colorForSection(_ section: String) -> Color {
        switch section {
        case "Getting Started": return .blue
        case "Smart Clean vs One-Click Clean": return .purple
        case "Flash Clean": return .yellow
        case "App Uninstall": return .orange
        case "Duplicate Files": return .indigo
        case "Large Files": return .green
        case "Startup Items": return .red
        case "Intelligence Tools": return .mint
        case "Keyboard Shortcuts": return .gray
        case "FAQ": return .teal
        case "Safety & Privacy": return .pink
        default: return .secondary
        }
    }
}

// MARK: - Getting Started
struct GettingStartedView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Welcome to DiskLense")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your complete Mac optimization toolkit")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                HelpListItem(
                    icon: "wand.and.stars",
                    color: .purple,
                    title: "Smart Clean",
                    description: "One-click deep cleaning. Removes junk files, duplicates, and large files from Downloads. Run weekly."
                )
                
                HelpListItem(
                    icon: "sparkles",
                    color: .blue,
                    title: "One-Click Clean",
                    description: "Quick daily cleaning. Safely removes temporary files, caches, and system junk."
                )
                
                HelpListItem(
                    icon: "chart.pie.fill",
                    color: .green,
                    title: "Real-time Stats",
                    description: "Your Mac's disk usage, memory, CPU, and system information at a glance."
                )
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            Text("Getting Started Tips:")
                .font(.headline)
                .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 12) {
                TipRow(number: 1, text: "Run Smart Clean first - it will find the most space to free up")
                TipRow(number: 2, text: "Check Large Files to find big files you may have forgotten")
                TipRow(number: 3, text: "Review Startup Items to speed up your Mac's boot time")
                TipRow(number: 4, text: "Use keyboard shortcuts (⌘1-6) to navigate faster")
            }
        }
    }
}

// MARK: - Smart Clean vs One-Click Clean
struct SmartCleanVsOneClickView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Smart Clean vs One-Click Clean")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Understanding the difference")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Divider()
            
            HStack(spacing: 30) {
                // Smart Clean Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                        
                        VStack(alignment: .leading) {
                            Text("Smart Clean")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Deep Clean")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("✓ Junk files & caches", systemImage: "checkmark")
                        Label("✓ Duplicate files", systemImage: "checkmark")
                        Label("✓ Large files in Downloads", systemImage: "checkmark")
                        Label("✓ Temporary data", systemImage: "checkmark")
                    }
                    .foregroundColor(.primary)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recommended:")
                            .font(.headline)
                        Text("Weekly")
                            .font(.subheadline)
                            .foregroundColor(.purple)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Time:")
                            .font(.headline)
                        Text("10-15 seconds")
                            .font(.subheadline)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Shortcut:")
                            .font(.headline)
                        HStack {
                            Image(systemName: "command")
                            Text("S")
                        }
                        .font(.subheadline)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
                
                // One-Click Clean Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                        
                        VStack(alignment: .leading) {
                            Text("One-Click Clean")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Quick Clean")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("✓ Junk files & caches", systemImage: "checkmark")
                        Label("✓ Temporary data", systemImage: "checkmark")
                        Label("✗ Duplicate files", systemImage: "xmark")
                            .foregroundColor(.secondary)
                        Label("✗ Large files", systemImage: "xmark")
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.primary)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recommended:")
                            .font(.headline)
                        Text("Daily")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Time:")
                            .font(.headline)
                        Text("5 seconds")
                            .font(.subheadline)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Shortcut:")
                            .font(.headline)
                        HStack {
                            Image(systemName: "command")
                            Text("C")
                        }
                        .font(.subheadline)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            
            Divider()
            
            Text("When to use which?")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    Text("•")
                    Text("**Use One-Click Clean** for daily maintenance. It's fast, safe, and keeps your Mac running smoothly.")
                }
                HStack(alignment: .top) {
                    Text("•")
                    Text("**Use Smart Clean** when you need more space, or once a week. It finds duplicates and large files that One-Click Clean doesn't touch.")
                }
                HStack(alignment: .top) {
                    Text("•")
                    Text("**Both are 100% safe** - they only delete files that are safe to remove.")
                }
            }
        }
    }
}

// MARK: - Flash Clean Help
struct FlashCleanHelpView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Flash Clean")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.yellow)
                Text("The core of One-Click Clean")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("What it cleans:")
                    .font(.headline)
                
                BulletPoint(text: "System caches - temporary files created by macOS")
                BulletPoint(text: "User caches - app data that can be safely regenerated")
                BulletPoint(text: "Logs - system and application log files")
                BulletPoint(text: "Temporary files - files meant to be temporary")
                BulletPoint(text: "Application Support - leftover data from apps")
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("What it NEVER deletes:")
                    .font(.headline)
                
                BulletPoint(text: "Your documents, photos, or music", icon: "lock.fill", color: .green)
                BulletPoint(text: "Application binaries (the apps themselves)", icon: "lock.fill", color: .green)
                BulletPoint(text: "System files required by macOS", icon: "lock.fill", color: .green)
                BulletPoint(text: "Personal data or settings", icon: "lock.fill", color: .green)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            
            Text("Flash Clean is the engine behind One-Click Clean. It's completely safe and can be run daily.")
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
    }
}

// MARK: - App Uninstall Help
struct AppUninstallHelpView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("App Uninstall")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Completely remove applications and their leftovers")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Features:")
                    .font(.headline)
                
                BulletPoint(text: "Scans all Applications folders")
                BulletPoint(text: "Shows app size and version")
                BulletPoint(text: "Finds hidden helper apps (like Office components)")
                BulletPoint(text: "Multiple selection - delete many apps at once")
                BulletPoint(text: "Confirmation dialog - no accidental deletions")
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("How to uninstall an app:")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    StepBox(number: 1, text: "Select app(s)")
                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)
                    StepBox(number: 2, text: "Click Remove")
                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)
                    StepBox(number: 3, text: "Confirm deletion")
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
            }
            
            Text("Unlike dragging to Trash, DiskLense finds and removes associated files like preferences, caches, and support files.")
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
    }
}

// MARK: - Duplicates Help
struct DuplicatesHelpView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Duplicate Files")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Find and remove duplicate documents")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("How it works:")
                    .font(.headline)
                
                BulletPoint(text: "Scans your home folder for duplicate files")
                BulletPoint(text: "Groups identical files together")
                BulletPoint(text: "Shows file names and locations")
                BulletPoint(text: "Delete individual copies or entire groups")
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Tips:")
                    .font(.headline)
                
                BulletPoint(text: "Keep at least one copy of each file", icon: "exclamationmark.triangle", color: .yellow)
                BulletPoint(text: "Check the file path before deleting", icon: "folder", color: .blue)
                BulletPoint(text: "Use Smart Clean to auto-clean duplicates", icon: "wand.and.stars", color: .purple)
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - Large Files Help
struct LargeFilesHelpView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Large Files")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Find files >100MB taking up space")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Features:")
                    .font(.headline)
                
                BulletPoint(text: "Sort by name, size, or date modified")
                BulletPoint(text: "Search for specific files")
                BulletPoint(text: "Multi-select with checkboxes")
                BulletPoint(text: "Delete individual files or in bulk")
                BulletPoint(text: "Smart Clean automatically cleans Downloads")
            }
            
            HStack(spacing: 20) {
                StatBadge(label: ">100MB", color: .orange)
                StatBadge(label: "Sortable", color: .blue)
                StatBadge(label: "Searchable", color: .green)
                StatBadge(label: "Multi-select", color: .purple)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Startup Items Help
struct StartupHelpView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Startup Items")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Control what launches when your Mac starts")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Three types of startup items:")
                    .font(.headline)
                
                HStack(spacing: 16) {
                    StartupTypeBox(
                        name: "Launch Agents",
                        icon: "person.fill",
                        color: .blue,
                        description: "Run when you log in"
                    )
                    
                    StartupTypeBox(
                        name: "Launch Daemons",
                        icon: "lock.shield",
                        color: .purple,
                        description: "System-wide background services"
                    )
                    
                    StartupTypeBox(
                        name: "Login Items",
                        icon: "power",
                        color: .orange,
                        description: "Apps that launch at login"
                    )
                }
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("What you can do:")
                    .font(.headline)
                
                BulletPoint(text: "View all startup items in organized folders")
                BulletPoint(text: "Enable/disable items without deleting")
                BulletPoint(text: "Remove items completely")
                BulletPoint(text: "See detailed information about each item")
            }
            
            Text("Disabling startup items can significantly speed up your Mac's boot time.")
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
    }
}

// MARK: - Intelligence Tools
struct IntelligenceToolsHelpView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Intelligence Tools")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Advanced analysis with clear, user-controlled actions")
                .font(.title3)
                .foregroundColor(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                Text("Disk Visualizer (Storage Map)")
                    .font(.headline)
                Text("What it does:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                BulletPoint(text: "Scans a folder and aggregates size by folder hierarchy")
                BulletPoint(text: "Shows Top N largest folders and their percentage of total")
                BulletPoint(text: "Lets you drill down to find heavy subfolders")
                BulletPoint(text: "Optionally treats app bundles as single items")

                Text("Example:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("You scan your Home folder. The map shows \"Movies\" at 42% and \"Xcode\" at 18%. You expand \"Xcode\" and see \"DerivedData\" is the main space user.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 14) {
                Text("Project Junk Detector")
                    .font(.headline)
                Text("What it does:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                BulletPoint(text: "Auto-detects known junk paths for installed apps")
                BulletPoint(text: "Groups by main category and shows subfolders")
                BulletPoint(text: "Explains each cache in plain language")
                BulletPoint(text: "Lets you add items to the Action List")

                Text("Example:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("If Xcode is installed, it shows DerivedData and Archives. You expand the Xcode category, review sizes, then add those folders to the Action List.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.06))
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 14) {
                Text("Old Files Analyzer")
                    .font(.headline)
                Text("What it does:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                BulletPoint(text: "Scans Downloads, Documents, Desktop, and media folders")
                BulletPoint(text: "Finds files not modified in 30/90 days or 1 year")
                BulletPoint(text: "Groups results by category and keeps sections collapsed")

                Text("Example:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Choose 90 days. It lists \"Stale Documents\" and \"Obsolete Installers\". Expand the category and add only the files you want to the Action List.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.orange.opacity(0.08))
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 14) {
                Text("Downloads Folder Intelligence")
                    .font(.headline)
                Text("What it does:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                BulletPoint(text: "Classifies downloads into installers, archives, images, videos, and audio")
                BulletPoint(text: "Finds DMGs with installed apps already in Applications")
                BulletPoint(text: "Detects archives where extracted folders still exist")

                Text("Example:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("A DMG from last month is detected, and the app is already installed. The tool suggests the DMG for review and lets you add it to the Action List.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.green.opacity(0.08))
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 14) {
                Text("Review & Decision Panel")
                    .font(.headline)
                Text("What it does:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                BulletPoint(text: "Collects items from all Intelligence Tools in one place")
                BulletPoint(text: "Shows total reclaimable size")
                BulletPoint(text: "Moves items to Trash only after confirmation")

                Text("Example:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("You add items from Disk Visualizer and Project Junk. In the panel you review the list, confirm, and items move to Trash with a log of the action.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.purple.opacity(0.08))
            .cornerRadius(12)
        }
    }
}

// MARK: - Keyboard Shortcuts
struct KeyboardShortcutsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Keyboard Shortcuts")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Work faster with these shortcuts")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Divider()
            
            HStack(alignment: .top, spacing: 40) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Navigation")
                        .font(.headline)
                    
                    ShortcutRow(key: "⌘1", description: "Go to Home")
                    ShortcutRow(key: "⌘2", description: "Go to Flash Clean")
                    ShortcutRow(key: "⌘3", description: "Go to App Uninstall")
                    ShortcutRow(key: "⌘4", description: "Go to Duplicates")
                    ShortcutRow(key: "⌘5", description: "Go to Large Files")
                    ShortcutRow(key: "⌘6", description: "Go to Startup Items")
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Actions")
                        .font(.headline)
                    
                    ShortcutRow(key: "⌘C", description: "One-Click Clean")
                    ShortcutRow(key: "⌘S", description: "Smart Clean")
                    ShortcutRow(key: "⌘R", description: "Refresh current tab")
                    ShortcutRow(key: "⌘,", description: "Settings")
                    ShortcutRow(key: "⌘?", description: "Help (coming soon)")
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            Text("Pro tip: Use keyboard shortcuts to navigate between tools without using the mouse!")
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)
        }
    }
}

// MARK: - FAQ
struct FAQView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Frequently Asked Questions")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 24) {
                FAQItem(
                    question: "Is DiskLense safe?",
                    answer: "Yes! DiskLense only deletes files that are safe to remove - caches, temporary files, and duplicates. It never touches your personal documents, photos, or system files."
                )
                
                FAQItem(
                    question: "What's the difference between One-Click Clean and Smart Clean?",
                    answer: "One-Click Clean is for daily use - it quickly removes junk files and caches. Smart Clean is for weekly deep cleaning - it also finds duplicates and large files in your Downloads folder."
                )
                
                FAQItem(
                    question: "Will App Uninstall delete my data?",
                    answer: "App Uninstall removes the application and its support files, but it never touches documents you created with the app. Your files remain safe."
                )
                
                FAQItem(
                    question: "How often should I run Smart Clean?",
                    answer: "Once a week is recommended. One-Click Clean can be run daily."
                )
                
                FAQItem(
                    question: "Can I recover deleted files?",
                    answer: "Deleted files are moved to Trash, so you can restore them from there before emptying Trash."
                )
                
                FAQItem(
                    question: "Why are some startup items disabled?",
                    answer: "Disabled items are still on your Mac but won't launch at startup. You can re-enable them anytime."
                )
            }
        }
    }
}

// MARK: - Safety & Privacy
struct SafetyView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Safety & Privacy")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your data is completely safe")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 24) {
                SafetyCard(
                    icon: "lock.shield.fill",
                    color: .green,
                    title: "No Personal Data Collected",
                    description: "DiskLense runs entirely on your Mac. No data is sent to any server. Your files never leave your computer."
                )
                
                SafetyCard(
                    icon: "trash.slash.fill",
                    color: .blue,
                    title: "Safe File Deletion",
                    description: "All deleted files go to Trash first. You can always restore them if needed."
                )
                
                SafetyCard(
                    icon: "checkmark.seal.fill",
                    color: .purple,
                    title: "Protected System Files",
                    description: "Critical system files are protected and cannot be deleted by DiskLense."
                )
                
                SafetyCard(
                    icon: "hand.raised.fill",
                    color: .orange,
                    title: "Confirmation Required",
                    description: "Every delete action requires confirmation. No accidental deletions."
                )
            }
        }
    }
}

// MARK: - Helper Components
struct HelpListItem: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(color)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TipRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text("\(number).")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .frame(width: 24, alignment: .leading)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct BulletPoint: View {
    let text: String
    var icon: String = "checkmark.circle.fill"
    var color: Color = .green
    
    init(text: String, icon: String = "checkmark.circle.fill", color: Color = .green) {
        self.text = text
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 16)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct StepBox: View {
    let number: Int
    let text: String
    
    var body: some View {
        VStack {
            Text("\(number)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            Text(text)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .frame(width: 100, height: 80)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

struct StatBadge: View {
    let label: String
    let color: Color
    
    var body: some View {
        Text(label)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(20)
    }
}

struct StartupTypeBox: View {
    let name: String
    let icon: String
    let color: Color
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(name)
                    .font(.headline)
            }
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ShortcutRow: View {
    let key: String
    let description: String
    
    var body: some View {
        HStack {
            Text(key)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .frame(width: 60, alignment: .leading)
            Text(description)
                .font(.subheadline)
        }
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.headline)
            Text(answer)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct SafetyCard: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(color)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
    }
}