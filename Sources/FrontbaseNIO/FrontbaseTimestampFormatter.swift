//
//  FrontbaseTimestampFormatter.swift
//  
//
//  Created by Johan Carlberg on 2023-04-11.
//

import Foundation

class FrontbaseTimestampFormatter: DateFormatter {

    let subsecondsFormat: String
    let divisor: Int

    init (_ precision: Int) {
        switch precision {
            case 0:
                self.subsecondsFormat = ""
                self.divisor = 1000000000

            case 1:
                self.subsecondsFormat = ".%01d"
                self.divisor = 100000000

            case 2:
                self.subsecondsFormat = ".%02d"
                self.divisor = 10000000

            case 3:
                self.subsecondsFormat = ".%03d"
                self.divisor = 1000000

            case 4:
                self.subsecondsFormat = ".%04d"
                self.divisor = 100000

            case 5:
                self.subsecondsFormat = ".%05d"
                self.divisor = 10000

            default:
                self.subsecondsFormat = ".%06d"
                self.divisor = 1000
        }
        super.init()
        self.calendar.timeZone = TimeZone (identifier: "UTC")!
    }
    
    required init?(coder: NSCoder) {
        fatalError ("init(coder:) has not been implemented")
    }
    
    override func string (from date: Date) -> String {
        let components = calendar.dateComponents ([ .year, .month, .day, .hour, .minute, .second, .nanosecond ], from: date)

        return String (format: "%04d-%02d-%02d %02d:%02d:%02d\(self.subsecondsFormat)", components.year!, components.month!, components.day!, components.hour!, components.minute!, components.second!, (components.nanosecond! + self.divisor / 2) / self.divisor)
    }
}
