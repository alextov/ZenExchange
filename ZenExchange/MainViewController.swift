//
//  MainViewController.swift
//  ZenExchange
//
//  Created by Alexander Tovstonozhenko on 05.01.15.
//  Copyright (c) 2015 Alexander Tovstonozhenko. All rights reserved.
//

import UIKit

let YQL_QUERY: String = "https://query.yahooapis.com/v1/public/yql?q=select%20Bid%2CAsk%2CBidRealtime%2CAskRealtime%2CName%2CSymbol%20from%20yahoo.finance.quotes%20where%20symbol%20in%20(%22USDRUB%3DX%2CEURRUB%3DX%2CBZQ15.NYM%2CEURUAH%3DX%2CUSDUAH%3DX%22)&format=json&diagnostics=true&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback="

enum TugrikSymbol: String {
    case UAH = "UAH"
    case RUB = "RUB"
}

struct Tugrik {
    var symbol: String
    var name: String
}

let tugriks: [TugrikSymbol: Tugrik] = [
    .UAH: Tugrik(symbol: TugrikSymbol.UAH.rawValue, name: "гривен"),
    .RUB: Tugrik(symbol: TugrikSymbol.RUB.rawValue, name: "рублей")
]

class MainViewController: UIViewController {

    @IBOutlet weak var tugriksPerDollarLabel: UILabel!
    @IBOutlet weak var tugriksPerEuroLabel: UILabel!
    @IBOutlet weak var dollarsPerBarrelLabel: UILabel!
    @IBOutlet weak var tugriksPerDollarCommentLabel: UILabel!
    @IBOutlet weak var tugriksPerEuroCommentLabel: UILabel!
    @IBOutlet weak var dollarsPerBarrelCommentLabel: UILabel!
    
    var currentTugrik: TugrikSymbol! = .UAH
    
    var tugrikName: String! {
        get {
            return tugriks[self.currentTugrik]!.name
        }
    }
    var tugriksPerDollarComment: String! {
        get {
            return tugrikName + " за доллар"
        }
    }
    var tugriksPerEuroComment: String! {
        get {
            return tugrikName + " за евро"
        }
    }
    let dollarsPerBarrelComment: String! = "долларов за баррель"
    
    
    // MARK: - Overridden methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        var timer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "fetchQuotes", userInfo: nil, repeats: true)
        
        showDummyResults()
        fetchQuotes()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Action methods
    
    @IBAction func ukrainianFlagTapped(sender: AnyObject) {
        if currentTugrik != .UAH {
            currentTugrik = .UAH
            fetchQuotes()
        }
    }

    @IBAction func russianFlagTapped(sender: AnyObject) {
        if currentTugrik != .RUB {
            currentTugrik = .RUB
            fetchQuotes()
        }
    }
    
    
    // MARK: - Private methods
    
    func fetchQuotes() {
        let url = NSURL(string: YQL_QUERY)!
        let request = NSURLRequest(URL: url)
        let queue = NSOperationQueue()
        NSURLConnection.sendAsynchronousRequest(request, queue: queue) { (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            if data != nil {
                let result: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
                let parsedResults = self.parseJSON(result)
                let symbol = tugriks[self.currentTugrik]!.symbol
                let dollarQuote = parsedResults.valueForKey("USD\(symbol)=X") as? Double ?? 0.0
                let euroQuote = parsedResults.valueForKey("EUR\(symbol)=X") as? Double ?? 0.0
                let oilQuote = parsedResults.valueForKey("BZQ15.NYM") as? Double ?? 0.0
                self.showResults(dollarQuote: dollarQuote, euroQuote: euroQuote, oilQuote: oilQuote)
            } else {
                self.showDummyResults()
            }
        }
    }
    
    func parseJSON(jsonObject: NSDictionary) -> NSDictionary {
        var result = NSMutableDictionary()
        let json = JSON(jsonObject)
        let quotes = json["query"]["results"]["quote"]
        for (index: String, quote: JSON) in quotes {
            let symbol = quote["Symbol"]
            var ask = quote["Ask"]
            if let askRealtime = quote["AskRealtime"].string {
                ask = quote["AskRealtime"]
            }
            result[symbol.string!] = (ask.string! as NSString).doubleValue
        }
        return result
    }
    
    func showResults(#dollarQuote: Double, euroQuote: Double, oilQuote: Double) {
        dispatch_async(dispatch_get_main_queue()) {
//            println("\(dollarQuote)\t\(euroQuote)\t\(oilQuote)")
            self.tugriksPerDollarLabel.text = String(format: "%.2f", dollarQuote)
            self.tugriksPerEuroLabel.text = String(format: "%.2f", euroQuote)
            self.dollarsPerBarrelLabel.text = String(format: "%.2f", oilQuote)
            self.tugriksPerDollarCommentLabel.text = self.tugriksPerDollarComment
            self.tugriksPerEuroCommentLabel.text = self.tugriksPerEuroComment
            self.dollarsPerBarrelCommentLabel.text = self.dollarsPerBarrelComment
        }
    }
    
    func showDummyResults() {
        dispatch_async(dispatch_get_main_queue()) {
            var dummyText: NSMutableArray = ["я чото п?", "guru meditation", "при пожаре звони 101", "не паникуй!", "в килобайте 1000 байт", "буду через 15 минут", "кто здесь?", "ж-ж-ж-ж-ж", "привет, как дела?", "my other car is a cdr", "скорее... эх, тоска"]
            for label in [self.tugriksPerDollarLabel, self.tugriksPerEuroLabel, self.dollarsPerBarrelLabel] {
                label.text = ""
            }
            for label in [self.tugriksPerDollarCommentLabel, self.tugriksPerEuroCommentLabel, self.dollarsPerBarrelCommentLabel] {
                let count = UInt32(dummyText.count)
                let index = Int(arc4random_uniform(count))
                label.text = dummyText[index] as? String ?? ""
                dummyText.removeObjectAtIndex(index)
            }
        }
    }

}
