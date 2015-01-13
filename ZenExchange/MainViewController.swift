//
//  MainViewController.swift
//  ZenExchange
//
//  Created by Alexander Tovstonozhenko on 05.01.15.
//  Copyright (c) 2015 Alexander Tovstonozhenko. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData

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

class FlyingTugrik {
    struct Static {
        static let gravity: CGFloat = 0.01
        static let size: CGFloat = 44.0
        static let min = 5
        static let max = 20
        static var minResistance = 0.1
        static var maxResistance = 0.5
        static var minLinearVelocity = -0.3
        static var maxLinearVelocity = 0.3
        static var minAngularVelocity = -0.3
        static var maxAngularVelocity = 0.3
    }
    var imageView: UIImageView!
    var itemBehavior: UIDynamicItemBehavior!
    var resistance: CGFloat!
    var linearVelocity: CGFloat!
    var angularVelocity: CGFloat!
    
    init(minX: CGFloat, maxX: CGFloat) {
        let x = CGFloat(randomNumberBetween(low: Int(minX), high: Int(maxX)))
        let y = CGFloat(-randomNumberBetween(low: Int(Static.size), high: Int(Static.size * 5)))
        imageView = UIImageView(frame: CGRectMake(x, y, Static.size, Static.size))
        imageView.image = UIImage(named: "banknote")

        resistance = CGFloat(randomNumberBetween(low: Int(Static.minResistance * 100), high: Int(Static.maxResistance * 100))) / 100.0
        linearVelocity = CGFloat(randomNumberBetween(low: Int(Static.minLinearVelocity * 100), high: Int(Static.maxLinearVelocity * 100))) / 100.0
        angularVelocity = CGFloat(randomNumberBetween(low: Int(Static.minAngularVelocity * 100), high: Int(Static.maxAngularVelocity * 100))) / 100.0
        
        itemBehavior = UIDynamicItemBehavior(items: [imageView])
        itemBehavior.resistance = resistance
        itemBehavior.addAngularVelocity(angularVelocity, forItem: imageView)
//        itemBehavior.addLinearVelocity(linearVelocity, forItem: imageView) // FIXME: what the acual fuck
    }
}

class MainViewController: UIViewController {

    @IBOutlet weak var ukrainianFlagButton: UIButton!
    @IBOutlet weak var russianFlagButton: UIButton!
    
    @IBOutlet weak var tugriksPerDollarLabel: UILabel!
    @IBOutlet weak var tugriksPerEuroLabel: UILabel!
    @IBOutlet weak var dollarsPerBarrelLabel: UILabel!
    @IBOutlet weak var tugriksPerDollarCommentLabel: UILabel!
    @IBOutlet weak var tugriksPerEuroCommentLabel: UILabel!
    @IBOutlet weak var dollarsPerBarrelCommentLabel: UILabel!
    
    @IBOutlet weak var obsoleteDataLabel: UILabel!
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    var currentBackgroundImageIndex: Int! = 0
    
    var animator: UIDynamicAnimator!
    var gravity: UIGravityBehavior!
    var collision: UICollisionBehavior!
    var flyingTugriks = NSMutableArray()
    
    var currentTugrik: TugrikSymbol! = .UAH
    var tugrikName: String! {
        get {
            return tugriks[self.currentTugrik]!.name
        }
    }
    var tugrikSymbol: String! {
        get {
            return tugriks[self.currentTugrik]!.symbol
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
    
    var shouldFetchTugriksAgain: Bool = true
    
    var audioPlayer: AVAudioPlayer!
    
    var reachability: Reachability!
    var defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
    
    
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
        
        reachability = Reachability(hostName: "query.yahooapis.com")
        reachability.reachableBlock = {
            (reach: Reachability!) -> Void in
            dispatch_async(dispatch_get_main_queue()) {
                self.fetchQuotes()
            }
        }
        
        // Load quote values.
        var timer = NSTimer.scheduledTimerWithTimeInterval(15.0, target: self, selector: "fetchQuotes", userInfo: nil, repeats: true)
        var flyingTugriksTimer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: "adjustFlyingTugriks", userInfo: nil, repeats: true)
        
        // While these are loading, show some dummy messages to entertain user.
        loadQuotes(tugriks[self.currentTugrik]!.symbol)
        fetchQuotes()
        
        initFlyingTugriks()
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
            ukrainianFlagButton.setBackgroundImage(UIImage(named: "UA"), forState: .Normal)
            russianFlagButton.setBackgroundImage(UIImage(named: "RU_disabled"), forState: .Normal)
        }
    }

    @IBAction func russianFlagTapped(sender: AnyObject) {
        if currentTugrik != .RUB {
            currentTugrik = .RUB
            fetchQuotes()
            setRandomBackground()
            ukrainianFlagButton.setBackgroundImage(UIImage(named: "UA_disabled"), forState: .Normal)
            russianFlagButton.setBackgroundImage(UIImage(named: "RU"), forState: .Normal)
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
        if !reachability.isReachable() {
            self.loadQuotes(tugrikSymbol)
            return
        }
        if !shouldFetchTugriksAgain {
//            return
        }
        shouldFetchTugriksAgain = false
        let url = NSURL(string: YQL_QUERY)!
        let request = NSURLRequest(URL: url)
        let queue = NSOperationQueue()
        NSURLConnection.sendAsynchronousRequest(request, queue: queue) { (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
//            println(data)
            let symbol = tugriks[self.currentTugrik]!.symbol
            if data != nil {
                let result: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
                if let parsedResults = self.parseJSON(result) {
                    let dollarQuote = parsedResults.valueForKey("USD\(symbol)=X") as? Double ?? 0.0
                    let euroQuote = parsedResults.valueForKey("EUR\(symbol)=X") as? Double ?? 0.0
                    let oilQuote = parsedResults.valueForKey("BZQ15.NYM") as? Double ?? 0.0
                    self.showResults(dollarQuote: dollarQuote, euroQuote: euroQuote, oilQuote: oilQuote)
                    self.saveQuotes(symbol, dollarQuote: dollarQuote, euroQuote: euroQuote, oilQuote: oilQuote)
                } else {
                    self.loadQuotes(symbol)
                }
            } else {
                self.loadQuotes(symbol)
            }
            self.shouldFetchTugriksAgain = true
        }
    }
    
    func saveQuotes(symbol: String, dollarQuote dollar: Double, euroQuote euro: Double, oilQuote oil: Double) {
        defaults.setDouble(dollar, forKey: "\(symbol)dollarQuote")
        defaults.setDouble(euro, forKey: "\(symbol)euroQuote")
        defaults.setDouble(oil, forKey: "\(symbol)oilQuote")
        defaults.synchronize()
        self.showObsoletionLabel(shouldHide: true)
    }
    
    func loadQuotes(symbol: String) {
        let dollarQuote = defaults.objectForKey("\(symbol)dollarQuote") as? Double
        let euroQuote = defaults.objectForKey("\(symbol)euroQuote") as? Double
        let oilQuote = defaults.objectForKey("\(symbol)oilQuote") as? Double
        if dollarQuote == nil || euroQuote == nil || oilQuote == nil {
            self.showDummyResults()
        } else {
            self.showResults(dollarQuote: dollarQuote!, euroQuote: euroQuote!, oilQuote: oilQuote!)
            self.showObsoletionLabel()
        }
    }
    
    func saveToCoreData(#quoteUsdUah: Double, quoteEurUah: Double, quoteUsdRub: Double, quoteEurRub: Double, quoteOil: Double) {
        let context = CoreDataManager.sharedInstance.managedObjectContext!
        let entity = NSEntityDescription.entityForName("Record", inManagedObjectContext: context)
        let record = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: context)
        record.setValuesForKeysWithDictionary([
            "date": NSDate(),
            "usdUah": quoteUsdUah,
            "eurUah": quoteEurUah,
            "usdRub": quoteUsdRub,
            "eurRub": quoteEurRub,
            "oil": quoteOil
        ])
        var error: NSError?
        if !context.save(&error) {
            println("Could not save \(error), \(error!.userInfo)")
        }
    }
    
    func fetchFromCoreData() -> [NSManagedObject]? {
        let context = CoreDataManager.sharedInstance.managedObjectContext!
        let request = NSFetchRequest(entityName: "Record")
        var error: NSError?
        let results = context.executeFetchRequest(request, error: &error) as? [NSManagedObject]
        return results
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
    
    func showObsoletionLabel(shouldHide: Bool = false) {
        dispatch_async(dispatch_get_main_queue()) {
            if shouldHide {
                self.obsoleteDataLabel.hidden = true
            } else {
                var dummyText: [String] = ["нет интернета, милорд", "это было давно и неправда", "давным-давно в далекой-далекой...", "ну или нет"]
                let count = UInt32(dummyText.count)
                let index = Int(arc4random_uniform(count))
                let text = dummyText[index]
                self.setTextAnimated(self.obsoleteDataLabel, text: text)
                self.obsoleteDataLabel.hidden = false
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
    
    /// Initialize falling images system.
    func initFlyingTugriks() {
        animator = UIDynamicAnimator(referenceView: self.view)
        gravity = UIGravityBehavior()
        gravity.gravityDirection = CGVectorMake(0.0, FlyingTugrik.Static.gravity)
        animator.addBehavior(gravity)

        let initialTugriksNumber = randomNumberBetween(low: 1, high: FlyingTugrik.Static.min)
        for _ in 1...initialTugriksNumber {
            addFlyingTugrik()
        }
    }
    
    /// Add one flying image in random place on X axis of the screen.
    func addFlyingTugrik() {
        let minX = self.view.frame.origin.x - FlyingTugrik.Static.size
        // Here instead of simply using width, we're checking for the largest
        // dimension of the device. By using such approach we can make sure 
        // that when user rotates their device they will see images all over
        // their screen rather than just in a narrow column on the left 
        // (when rotating from portrait to landscape).
        let maxX = max(self.view.frame.height, self.view.frame.width)
        let y = -FlyingTugrik.Static.size
        
        let flyingTugrik = FlyingTugrik(minX: minX, maxX: maxX)
        self.view.insertSubview(flyingTugrik.imageView, aboveSubview: self.backgroundImageView)
        gravity.addItem(flyingTugrik.imageView)
        
        animator.addBehavior(flyingTugrik.itemBehavior)
        
        self.flyingTugriks.addObject(flyingTugrik)
    }
    
    /// Remove unneded images and adjust horizontal/vertical velocities of existing ones.
    func adjustFlyingTugriks() {
        var numberOfTugriksTotal = self.flyingTugriks.count
        
        // Check if max number of images has been reached.
        if numberOfTugriksTotal < FlyingTugrik.Static.max {
            // If not, add some random number of images (but not too many).
            let numberOfTugriksToAdd = randomNumberBetween(low: 1, high: (FlyingTugrik.Static.max - FlyingTugrik.Static.min) / 3)
            for _ in 1...numberOfTugriksToAdd {
                addFlyingTugrik()
            }
        }
        
        // Variable to store indexes of images that have hidden below bottom border
        // of the screen.
        var tugriksToRemove = NSMutableIndexSet()
        
        // Check which images have already hidden and don't need to be stored
        // anymore.
        for index in 0...numberOfTugriksTotal - 1 {
            let flyingTugrik = self.flyingTugriks[index] as FlyingTugrik
            if flyingTugrik.imageView.frame.origin.y > self.view.frame.height {
                flyingTugrik.imageView.removeFromSuperview()
                tugriksToRemove.addIndex(index)
            } else {
                // TODO: adjust horizontal/vertical velocity
            }
        }
        // After all iterations are done, remove already invisible images.
        self.flyingTugriks.removeObjectsAtIndexes(tugriksToRemove)
    }

}

/// Return random Int number between low and high.
func randomNumberBetween(#low: Int, #high: Int) -> Int {
    let result = Int(arc4random_uniform(UInt32(high - low + 1))) + low
    return result
}
