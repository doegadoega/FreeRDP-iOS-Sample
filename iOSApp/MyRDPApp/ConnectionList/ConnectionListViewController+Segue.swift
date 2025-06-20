//
//  ConnectionListViewController+Segue.swift
//  MyRDPApp
//
//  Created by Hiroshi Egami on 2025/06/19.
//

///  segueの処理を記述
extension ConnectionListViewController {
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRDPScreen" {
            if let rdpScreenVC = segue.destination as? RDPScreenViewController,
               let connection = self.selectConnection {
                // 選択された接続情報をRDPScreenViewControllerに渡す
                rdpScreenVC.connection = connection
            }
        }
    }
}
