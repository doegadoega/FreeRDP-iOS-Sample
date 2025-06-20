import Foundation
import UIKit

import RswiftResources

protocol ConnectionListViewControllerDelegate: AnyObject {
    func connectionListViewController(_ controller: ConnectionListViewController, didSelectConnection connection: RDPConnection)
}

class ConnectionListViewController: UIViewController {
    // Delegate
    weak var delegate: ConnectionListViewControllerDelegate?
    
    // MARK: - Outletss
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            self.tableView.delegate = self
            self.tableView.dataSource = self
            self.tableView.register(UINib(resource: R.nib.connectionListCell),
                                    forCellReuseIdentifier: R.nib.connectionListCell.name)
        }
    }
    
    var selectConnection: RDPConnection?
    
    // MARK: - Properties
    private var connections: [RDPConnection] = []
    
    // MARK: - Actions
    @IBAction func addButtonTapped() {
        let storyboard = UIStoryboard(name: "AddConnectionViewController", bundle: nil)
        if let addConnectionVC = storyboard.instantiateInitialViewController() as? AddConnectionViewController {
            navigationController?.pushViewController(addConnectionVC, animated: true)
        }
    }
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        self.loadConnections()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadConnections()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        self.title = "接続先一覧"
        self.view.backgroundColor = .systemBackground
    }
    
    private func loadConnections() {
        connections = RDPConnectionManager.shared.connections
        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ConnectionListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return connections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.connectionListCell.name, for: indexPath)
        let connection = connections[indexPath.row]
        
        if let cell = cell as? ConnectionListCell {
            cell.update(connection: connection)
        }
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
            // index
            self.selectConnection = self.connections[indexPath.row]
            // RDPScreenViewControllerを表示
            self.performSegue(withIdentifier: R.segue.connectionListViewController.showRDPScreen.identifier, sender: self)
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
