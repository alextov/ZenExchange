//
//  LogTableViewController.swift
//  ZenExchange
//
//  Created by Alexander Tovstonozhenko on 13.01.15.
//  Copyright (c) 2015 Alexander Tovstonozhenko. All rights reserved.
//

import UIKit
import CoreData

class LogTableViewController: UIViewController, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var records: NSArray!

    
    // MARK: - Overridden methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let records = self.fetchFromCoreData() {
            self.records = records
        }
    }

    /*
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 0
    }
    */

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
    
    
    // MARK: - Private methods
    
    func fetchFromCoreData() -> [NSManagedObject]? {
        let context = CoreDataManager.sharedInstance.managedObjectContext!
        let request = NSFetchRequest(entityName: "Record")
        var error: NSError?
        let results = context.executeFetchRequest(request, error: &error) as? [NSManagedObject]
        return results
    }
    
    func dateToString(date: NSDate) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .ShortStyle
        return dateFormatter.stringFromDate(date)
    }
    
    
    // MARK: - Delegated methods
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return records.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kReuseCellIdentifier, forIndexPath: indexPath) as UITableViewCell
        
        if let record = records[indexPath.row] as? Record {
            cell.textLabel!.text = dateToString(record.date)
        }
        
        return cell
    }

}
