//
//  RootViewController.swift
//  LocationTracking
//
//  Created by apple on 10/15/18.
//  Copyright © 2018 apple. All rights reserved.
//

import UIKit

class RootViewController: UITableViewController {

    var datasource = ["Demo","Live"]
    let cellId = "cell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        self.title = ""
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        cell.textLabel?.text = datasource[indexPath.item]
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if datasource[indexPath.row] == "Demo"{
            let vc = storyboard?.instantiateViewController(withIdentifier: "ViewController") as! ViewController
            vc.isDemo = true
            self.navigationController?.pushViewController(vc, animated: true)
        }else{
            let vc = storyboard?.instantiateViewController(withIdentifier: "ViewController") as! ViewController
            vc.isDemo = false
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

}
