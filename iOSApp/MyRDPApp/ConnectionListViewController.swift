import Foundation
import UIKit

protocol ConnectionListViewControllerDelegate: AnyObject {
    func connectionListViewController(_ controller: ConnectionListViewController, didSelectConnection connection: RDPConnection)
}

class ConnectionListViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    
    private var connections: [RDPConnection] = []
    weak var delegate: ConnectionListViewControllerDelegate?
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadConnections()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadConnections()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        title = "接続先一覧"
        view.backgroundColor = .systemBackground
    }
    
    private func loadConnections() {
        connections = RDPConnectionManager.shared.connections
        tableView.reloadData()
    }
    
    // MARK: - Actions
    
    @IBAction func addButtonTapped() {
        let storyboard = UIStoryboard(name: "AddConnectionViewController", bundle: nil)
        if let addConnectionVC = storyboard.instantiateInitialViewController() as? AddConnectionViewController {
            navigationController?.pushViewController(addConnectionVC, animated: true)
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension ConnectionListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return connections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConnectionCell", for: indexPath)
        let connection = connections[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = connection.name
        content.secondaryText = "\(connection.host):\(connection.port)"
        cell.contentConfiguration = content
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let connection = connections[indexPath.row]
        
        // 接続処理を実行
        if let delegate = delegate {
            delegate.connectionListViewController(self, didSelectConnection: connection)
            navigationController?.popViewController(animated: true)
        } else {
            // RDPScreenViewControllerを表示
            let storyboard = UIStoryboard(name: "RDPScreenViewController", bundle: nil)
            if let rdpScreenVC = storyboard.instantiateInitialViewController() as? RDPScreenViewController {
                rdpScreenVC.connection = connection
                navigationController?.pushViewController(rdpScreenVC, animated: true)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let connection = connections[indexPath.row]
            RDPConnectionManager.shared.deleteConnection(withId: connection.id)
            loadConnections()
        }
    }
}
