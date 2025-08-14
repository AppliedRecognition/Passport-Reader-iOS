//
//  NameUtil.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 13/08/2025.
//

import Foundation

struct NameUtil {
    
    private init() {}
    
    /// Convert ALL-CAPS MRZ-style names into human capitalization.
    /// Handles prefixes (Mc/Mac/O’/St.), particles (de/van/von/…),
    /// hyphenated names, and apostrophes.
    ///
    /// Examples:
    ///  - "MCDONALD"            -> "McDonald"
    ///  - "MACINTYRE"           -> "MacIntyre"
    ///  - "O'CONNOR"            -> "O’Connor"
    ///  - "VAN DER MEER"        -> "Van der Meer"
    ///  - "DE-LA CROIX"         -> "de-la Croix"  (mid-name particles lowercased, incl. after hyphen)
    ///  - "ANNE-MARIE"          -> "Anne-Marie"
    static func humanizeName(_ allCaps: String) -> String {
        // 1) Base pass: lowercase then title-case (handles spaces, hyphens, apostrophes)
        var name = allCaps.lowercased().capitalized
        
        // 2) Normalize apostrophes to typographic and ensure capitalization after them
        //    (e.g., O'connor -> O’Connor, D'Angelo -> D’Angelo)
        name = name.replacingOccurrences(of: #"['’]([A-Za-z])"#,
                                         with: #"’$1"#,
                                         options: .regularExpression)
        
        // 3) Special prefixes that need internal caps
        let fixes: [(pattern: String, replacement: String)] = [
            // McDonald
            (#"\bMc([A-Z])"#, "Mc$1"),
            // MacIntyre (note: not every "Mac" surname is CamelCase; this heuristic is common)
            (#"\bMac([A-Z])"#, "Mac$1"),
            // O’Connor / O'Brien
            (#"\bO[’']([A-Z])"#, "O’$1"),
            // St. John
            (#"\bSt\.\s+([A-Z])"#, "St. $1")
        ]
        
        for rule in fixes {
            name = name.replacingOccurrences(
                of: rule.pattern,
                with: rule.replacement,
                options: .regularExpression
            )
        }
        
        name = name.replacingMatches(pattern: #"(?<=\S\s)[DLdl][’]([A-Z])"#) { match in
            let first = String(match.prefix(1)).lowercased()
            let letter = match.last!
            return first + "’" + String(letter)
        }
        
        // 4) Lowercase particles not at the very start — including after hyphens
        // Particles list is opinionated; tweak for your data set.
        let particles: Set<String> = [
            "De","Del","Della","Di","Da","Dos","Das","Do",
            "Der","Den","Van","Von","Zu","Zum","Zur",
            "Du","DeLa","DeLe","DeLos","DeLas","La","Le","Lo","Las","Los"
        ]
        
        // Split by spaces, then by hyphens; lowercase particle tokens if:
        //  - not the first space-separated word in the whole name, OR
        //  - not the first subpart within a hyphenated token.
        let spaced = name.split(separator: " ")
        let rebuiltWords: [String] = spaced.enumerated().map { wordIndex, word in
            let hyphenParts = word.split(separator: "-")
            let rebuiltParts: [String] = hyphenParts.enumerated().map { subIndex, part in
                let s = String(part)
                // Strip apostrophes for particle comparison (e.g., "D’" considered a particle)
                let normalized = s.replacingOccurrences(of: "’", with: "").replacingOccurrences(of: "'", with: "")
                if (wordIndex > 0 || subIndex > 0), particles.contains(normalized) {
                    return s.lowercased()
                }
                return s
            }
            return rebuiltParts.joined(separator: "-")
        }
        name = rebuiltWords.joined(separator: " ")
        
        return name
    }

}

private extension String {
    /// Replace each regex match with a transform of the full matched string.
    func replacingMatches(pattern: String, options: NSRegularExpression.Options = [], transform: (String) -> String) -> String {
        let regex = try! NSRegularExpression(pattern: pattern, options: options)
        let ns = self as NSString
        var result = self
        var offset = 0
        for m in regex.matches(in: self, range: NSRange(location: 0, length: ns.length)) {
            let r = NSRange(location: m.range.location + offset, length: m.range.length)
            guard let rr = Range(r, in: result) else { continue }
            let full = String(result[rr])
            let replacement = transform(full)
            result.replaceSubrange(rr, with: replacement)
            offset += replacement.utf16.count - r.length
        }
        return result
    }
    }
