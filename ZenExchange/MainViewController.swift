//
//  MainViewController.swift
//  ZenExchange
//
//  Created by Alexander Tovstonozhenko on 05.01.15.
//  Copyright (c) 2015 Alexander Tovstonozhenko. All rights reserved.
//

import UIKit

let YQL_QUERY: String = "https://query.yahooapis.com/v1/public/yql?q=select%20Bid%2CAsk%2CBidRealtime%2CAskRealtime%2CName%2CSymbol%20from%20yahoo.finance.quotes%20where%20symbol%20in%20(%22USDRUB%3DX%2CEURRUB%3DX%2CBZQ15.NYM%2CEURUAH%3DX%2CUSDUAH%3DX%22)&format=json&diagnostics=true&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys&callback="

class MainViewController: UIViewController {

    @IBOutlet weak var tugriksPerDollarLabel: UILabel!
    @IBOutlet weak var tugriksPerDollarCommentLabel: UILabel!
    @IBOutlet weak var tugriksPerEuroLabel: UILabel!
    @IBOutlet weak var tugriksPerEuroCommentLabel: UILabel!
    @IBOutlet weak var dollarsPerBarrelLabel: UILabel!
    @IBOutlet weak var dollarsPerBarrelCommentLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        showDummyResults()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func showDummyResults() {
        var dummyText: NSMutableArray = ["я чото п?", "guru meditation", "при пожаре звони 101", "не паникуй!", "в килобайте 1000 байт", "буду через 15 минут", "кто здесь?", "ж-ж-ж-ж-ж", "привет, как дела?", "my other car is a cdr"]
        for label in [tugriksPerDollarLabel, tugriksPerEuroLabel, dollarsPerBarrelLabel] {
            label.text = "–"
        }
        for label in [tugriksPerDollarCommentLabel, tugriksPerEuroCommentLabel, dollarsPerBarrelCommentLabel] {
            let count = UInt32(dummyText.count)
            let index = Int(arc4random_uniform(count))
            label.text = dummyText[index] as? String ?? ""
            dummyText.removeObjectAtIndex(index)
        }
    }

}
