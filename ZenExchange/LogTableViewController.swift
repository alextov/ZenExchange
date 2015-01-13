//
//  LogTableViewController.swift
//  ZenExchange
//
//  Created by Alexander Tovstonozhenko on 13.01.15.
//  Copyright (c) 2015 Alexander Tovstonozhenko. All rights reserved.
//

import UIKit

class LogTableViewController: UITableViewController {

    
    // MARK: - Overridden methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kReuseCellIdentifier, forIndexPath: indexPath) as UITableViewCell


        return cell
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
    
    
    // MARK: - Action methods
    
    @IBAction func swipeWasDetected(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}
