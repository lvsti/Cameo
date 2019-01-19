//
//  FourCCDatabase.swift
//  Cameo
//
//  Created by Tamás Lustyik on 2018. 12. 30..
//  Copyright © 2018. Tamas Lustyik. All rights reserved.
//

import Foundation

struct FourCCEntry: Decodable {
    let fourCC: String
    let rawValue: Int
    let constantName: String
}

class FourCCDatabase {
    
    private let entries: [FourCCEntry]
    static let shared = FourCCDatabase()

    private init() {
        let url = Bundle.main.url(forResource: "fourcc.json", withExtension: nil)!
        let data = try! Data(contentsOf: url)
        let decoder = JSONDecoder()
        entries = try! decoder.decode([FourCCEntry].self, from: data)
    }
    
    func entry(forValue value: Int) -> FourCCEntry? {
        return entries.first { $0.rawValue == value }
    }
    
    func entriesMatching(_ searchTerm: String) -> [FourCCEntry] {
        return entries.filter {
            $0.constantName.localizedCaseInsensitiveContains(searchTerm) ||
            $0.fourCC.localizedCaseInsensitiveContains(searchTerm) ||
            String($0.rawValue, radix: 16, uppercase: false).localizedCaseInsensitiveContains(searchTerm) ||
            ((searchTerm.hasPrefix("0x") || searchTerm.hasPrefix("0X")) &&
                "0x\(String($0.rawValue, radix: 16, uppercase: false))".localizedCaseInsensitiveContains(searchTerm)) ||
            String($0.rawValue, radix: 10, uppercase: false).contains(searchTerm)
        }
    }
    
}
