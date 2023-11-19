//
//  ReportOutcomeOperation.swift
//  FiveCalls
//
//  Created by Ben Scheirman on 2/4/17.
//  Copyright © 2017 5calls. All rights reserved.
//

import Foundation

class ReportOutcomeOperation : BaseOperation {
    
    //Input properties
    var log: ContactLog
    var outcome: Outcome
    
    //Output properties
    var httpResponse: HTTPURLResponse?
    var error: Error?
    
    init(log: ContactLog, outcome: Outcome) {
        self.log = log
        self.outcome = outcome
    }

    override func execute() {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let url = URL(string: "https://api.5calls.org/v1/report")!

        // rather than avoiding network calls during debug,
        // indicate they shouldn't be included in counts
        let via: String
        #if DEBUG
            via = "test"
        #else
            via = "ios"
        #endif

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(AnalyticsManager.shared.callerID, forHTTPHeaderField: "X-Caller-ID")

        let query = "result=\(outcome.label)&contactid=\(log.contactId)&issueid=\(log.issueId)&phone=\(log.phone)&via=\(via)&callerid=\(AnalyticsManager.shared.callerID)"
        guard let data = query.data(using: .utf8) else {
            print("error creating HTTP POST body")
            return
        }
        request.httpBody = data
        let task = session.dataTask(with: request) { (data, response, error) in
            if let e = error {
                self.error = e
            } else {
                let http = response as! HTTPURLResponse
                self.httpResponse = http
                if let _ = data, http.statusCode == 200 {
                    print("sent report successfully")
                    var logs = ContactLogs.load()
                    logs.markReported(self.log)
                    logs.save()
                }
            }
            self.finish()
        }
        task.resume()
    }
}
