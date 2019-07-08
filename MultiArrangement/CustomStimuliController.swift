//
//  CustomStimuliController.swift
//  MultiArrangement
//
//  Created by Budding Minds Admin on 2019-04-18.
//  Copyright © 2019 Budding Minds Admin. All rights reserved.
//

import UIKit

class CustomStimuliController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var data = [String]()
    var subjectID = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self as UITableViewDataSource
        // make sure data is non-nil
        data = process_data(input: load_data(fileName: "words", fileType: "csv"))
        tableView.delegate = self
        tableView.setEditing(true, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellReuseIdentifier") as! CustomTableViewCell
        let text = data[indexPath.row]
        cell.textLabel?.text = text
        cell.tintColor = UIColor.blue
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("selected row")
        print(indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle(rawValue: 3)!
    }
    
    func process_data(input: [String]) -> [String] {
        var result = [String]()
        for rowI in 1 ..< input.count {
            let rowList = input[rowI].components(separatedBy: ",")
            result.append(rowList[6 - 1])
        }
        return result
    }
    
    func load_data(fileName: String, fileType: String) -> [String]! {
        guard let filepath = Bundle.main.path(forResource: fileName, ofType: fileType)
            else {
                return nil
        }
        do {
            let contents = try String(contentsOfFile: filepath, encoding: .utf8)
            let data = contents.components(separatedBy: "\r")
            return data
        } catch {
            return nil
        }
    }
    
    @IBAction func arrange(_ sender: Any) {
        let rows = tableView.indexPathsForSelectedRows
//        print("rows is")
//        print(rows!)
//        print("data is")
        data = map(indexPaths: rows!)
//        print(data)
        performSegue(withIdentifier: "CustomToCircle", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destVC: TestCircleArenaController = segue.destination as! TestCircleArenaController
        destVC.subjectID = subjectID
        //destVC.stimuli = data
    }
    
    // maps the indexPaths obtained from multiple selection onto their corresponding string value
    func map(indexPaths: [IndexPath]) -> [String] {
        var result = [String]()
        for index in indexPaths {
            result.append(data[index.row])
        }
        return result
    }
    
}
