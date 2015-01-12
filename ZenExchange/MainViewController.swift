//
//  MainViewController.swift
//  ZenExchange
//
//  Created by Alexander Tovstonozhenko on 05.01.15.
//  Copyright (c) 2015 Alexander Tovstonozhenko. All rights reserved.
//

import UIKit
import AVFoundation

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

    @IBOutlet weak var ukrainianFlagButton: UIButton!
    @IBOutlet weak var russianFlagButton: UIButton!
    
    @IBOutlet weak var tugriksPerDollarLabel: UILabel!
    @IBOutlet weak var tugriksPerEuroLabel: UILabel!
    @IBOutlet weak var dollarsPerBarrelLabel: UILabel!
    @IBOutlet weak var tugriksPerDollarCommentLabel: UILabel!
    @IBOutlet weak var tugriksPerEuroCommentLabel: UILabel!
    @IBOutlet weak var dollarsPerBarrelCommentLabel: UILabel!
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    var currentBackgroundImageIndex: Int! = 0
    
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
    
    var audioPlayer: AVAudioPlayer!
    
    
    // MARK: - Overridden methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Set random background image.
        setRandomBackground(animated: false)
        
        // Play music.
        let bgmusic = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("bgmusic", ofType: "mp3")!)

        AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient, error: nil)
        AVAudioSession.sharedInstance().setActive(true, error: nil)
        
        var error: NSError?
        audioPlayer = AVAudioPlayer(contentsOfURL: bgmusic, error: &error)
        audioPlayer.numberOfLoops = -1
        audioPlayer.prepareToPlay()
//        audioPlayer.play()
        
        // Load quote values.
        var timer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "fetchQuotes", userInfo: nil, repeats: true)
        
        // While these are loading, show some dummy messages to entertain user.
        showDummyResults()
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
            setRandomBackground()
        }
    }

    @IBAction func russianFlagTapped(sender: AnyObject) {
        if currentTugrik != .RUB {
            currentTugrik = .RUB
            fetchQuotes()
            setRandomBackground()
        }
    }
    
    @IBAction func backgroundTapped(sender: AnyObject) {
        if audioPlayer.playing {
            self.audioPlayer.pause()
        } else {
            self.audioPlayer.play()
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
                if let parsedResults = self.parseJSON(result) {
                    let symbol = tugriks[self.currentTugrik]!.symbol
                    let dollarQuote = parsedResults.valueForKey("USD\(symbol)=X") as? Double ?? 0.0
                    let euroQuote = parsedResults.valueForKey("EUR\(symbol)=X") as? Double ?? 0.0
                    let oilQuote = parsedResults.valueForKey("BZQ15.NYM") as? Double ?? 0.0
                    self.showResults(dollarQuote: dollarQuote, euroQuote: euroQuote, oilQuote: oilQuote)
                } else {
                    self.showDummyResults()
                }
            } else {
                self.showDummyResults()
            }
        }
    }
    
    func parseJSON(jsonObject: NSDictionary) -> NSDictionary? {
        var result = NSMutableDictionary()
        let json = JSON(jsonObject)
        if json["error"] == nil {
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
        } else {
            return nil
        }
    }
    
    func showResults(#dollarQuote: Double, euroQuote: Double, oilQuote: Double) {
        dispatch_async(dispatch_get_main_queue()) {
//            println("\(dollarQuote)\t\(euroQuote)\t\(oilQuote)")
            self.setTextAnimated(self.tugriksPerDollarLabel, text: String(format: "%.2f", dollarQuote))
            self.setTextAnimated(self.tugriksPerEuroLabel, text: String(format: "%.2f", euroQuote))
            self.setTextAnimated(self.dollarsPerBarrelLabel, text: String(format: "%.2f", oilQuote))
            self.setTextAnimated(self.tugriksPerDollarCommentLabel, text: self.tugriksPerDollarComment)
            self.setTextAnimated(self.tugriksPerEuroCommentLabel, text: self.tugriksPerEuroComment)
            self.setTextAnimated(self.dollarsPerBarrelCommentLabel, text: self.dollarsPerBarrelComment)
        }
    }
    
    func showDummyResults() {
        dispatch_async(dispatch_get_main_queue()) {
            var dummyText: NSMutableArray = ["я чото п?", "guru meditation", "при пожаре звони 101", "не паникуй!", "в килобайте 1000 байт", "буду через 15 минут", "кто здесь?", "ж-ж-ж-ж-ж", "привет, как дела?", "my other car is a cdr", "скорее... эх, тоска"]
            for label in [self.tugriksPerDollarLabel, self.tugriksPerEuroLabel, self.dollarsPerBarrelLabel] {
                self.setTextAnimated(label, text: "")
            }
            for label in [self.tugriksPerDollarCommentLabel, self.tugriksPerEuroCommentLabel, self.dollarsPerBarrelCommentLabel] {
                let count = UInt32(dummyText.count)
                let index = Int(arc4random_uniform(count))
                let text = dummyText[index] as? String ?? ""
                self.setTextAnimated(label, text: text)
                dummyText.removeObjectAtIndex(index)
            }
        }
    }
    
    func setTextAnimated(label: UILabel, text: String) {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        animation.type = kCATransitionFade
        animation.duration = 0.75
        label.layer.addAnimation(animation, forKey: "kCATransitionFade")
        label.text = text
    }
    
    func setRandomBackground(animated: Bool = true) {
        // FIXME: rework this pile of filth
        let backgroundCount = 3
        var availableBackgroundNumbers = [Int]()
        for index in 1...backgroundCount {
            if self.currentBackgroundImageIndex != index {
                availableBackgroundNumbers.append(index)
            }
        }
        let index = Int(arc4random_uniform(UInt32(backgroundCount) - 1))
        let backgroundNumber = availableBackgroundNumbers[index]
        self.currentBackgroundImageIndex = backgroundNumber
        let backgroundName = "background" + String(backgroundNumber)
        let backgroundImage = UIImage(named: backgroundName)
        
        if animated {
            let backgroundImageView = UIImageView(image: self.backgroundImageView.image)
            backgroundImageView.setTranslatesAutoresizingMaskIntoConstraints(false)
            backgroundImageView.contentMode = UIViewContentMode.ScaleAspectFill
            self.view.insertSubview(backgroundImageView, aboveSubview: self.backgroundImageView)
            
            let viewsDictionary = ["backgroundImageView": backgroundImageView]
            let constraintH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[backgroundImageView]-0-|", options: nil, metrics: nil, views: viewsDictionary)
            let constraintV = NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[backgroundImageView]-0-|", options: nil, metrics: nil, views: viewsDictionary)
            self.view.addConstraints(constraintH)
            self.view.addConstraints(constraintV)
            
            let animationDuration = 0.5
            UIImageView.animateWithDuration(animationDuration,
                animations: {
                    () -> Void in
                    backgroundImageView.alpha = 0.0
                },
                completion: {
                    (finished: Bool) -> Void in
                    backgroundImageView.removeFromSuperview()
                }
            )
        }
        
        self.backgroundImageView.image = backgroundImage
    }
    
    func executeWithDelay(delay: Double, callback: () -> ()) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), callback)
    }

}
