//
//  LogTableViewController.swift
//  ZenExchange
//
//  Created by Alexander Tovstonozhenko on 13.01.15.
//  Copyright (c) 2015 Alexander Tovstonozhenko. All rights reserved.
//

import UIKit
import CoreData

class LogTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var records: NSArray!

    
    // MARK: - Overridden methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let records = self.fetchFromCoreData() {
            self.records = records
        }
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
    
    @IBAction func clearButtonTapped(sender: AnyObject) {
        var alert = UIAlertController(title: "Подтвердите", message: "Действительно очистить все сохраненные данные?", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Очистить", style: .Destructive, handler: {
            _ in
            self.clearCoreData()
            self.records = []
            self.tableView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "Не очищать", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    // MARK: - Private methods
    
    func fetchFromCoreData() -> [NSManagedObject]? {
        let context = CoreDataManager.sharedInstance.managedObjectContext!
        let request = NSFetchRequest(entityName: "Record")
        
        var error: NSError?
        let results = context.executeFetchRequest(request, error: &error) as? [NSManagedObject]
        return results
    }
    
    func clearCoreData() {
        let context = CoreDataManager.sharedInstance.managedObjectContext!
        let request = NSFetchRequest(entityName: "Record")
        request.includesPropertyValues = false // only fetch the managedObjectID
        
        var error: NSError?
        if let results = context.executeFetchRequest(request, error: &error) {
            for record in results {
                context.deleteObject(record as NSManagedObject)
            }
        }
        
        error = nil
        if !context.save(&error) {
            println("Could not clear \(error), \(error!.userInfo)")
        }
    }
    
    
    // MARK: - Delegated methods
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return records.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kReuseCellIdentifier, forIndexPath: indexPath) as LogTableViewCell
        
        if let record = records[indexPath.row] as? Record {
            cell.fillValues(
                quoteUahUsd: record.usdUah as? Double ?? 0.0,
                quoteUahEur: record.eurUah as? Double ?? 0.0,
                quoteRubUsd: record.usdRub as? Double ?? 0.0,
                quoteRubEur: record.eurRub as? Double ?? 0.0,
                quoteUsdOil: record.oil as? Double ?? 0.0)
        }
        
        return cell
    }

}
