import Foundation
import UIKit

// R.swiftのライブラリ名を正しく指定
import RswiftResources

class MainViewController: UIViewController {
    
    // MARK: - Properties
    
    private var rdpConnectionManager: RDPConnectionManager?
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupRDPComponents()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        title = "FreeRDP Client"
        view.backgroundColor = .systemBackground
    }
    
    private func setupRDPComponents() {
        // RDP接続マネージャーの初期化
        rdpConnectionManager = RDPConnectionManager.shared
    }
    
    // MARK: - Actions
    /// 接続先一覧を表示するアクション
    @IBAction func showConnectionList(_ sender: UIButton) {
        self.performSegue(withIdentifier: R.segue.mainViewController.showConnectionList.identifier,
                          sender: self)
    }
    
    @IBAction func addNewConnection(_ sender: UIButton) {
        // 現在はこちらで動作するようにしておく
        self.performSegue(withIdentifier: "showAddConnection", sender: self)
        
        // R.swiftが正しく設定されたらコメントアウトを解除して以下を使用
        // スペルミスと参照方法を修正
         self.performSegue(withIdentifier: R.segue.mainViewController.showAddConnection, sender: self)
    }
}

// MARK: - ConnectionListViewControllerDelegate

extension MainViewController: ConnectionListViewControllerDelegate {
    func connectionListViewController(_ controller: ConnectionListViewController, didSelectConnection connection: RDPConnection) {
        // RDPScreenViewControllerを表示
        let storyboard = UIStoryboard(name: "RDPScreenViewController", bundle: nil)
        if let rdpScreenVC = storyboard.instantiateInitialViewController() as? RDPScreenViewController {
            rdpScreenVC.connection = connection
            navigationController?.pushViewController(rdpScreenVC, animated: true)
        }
    }
}
