import UIKit

class ConnectionListViewController: UIViewController {
    private let tableView = UITableView()
    private var connections: [RDPConnection] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadConnections()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadConnections()
    }
    
    private func setupUI() {
        title = "接続先一覧"
        view.backgroundColor = .systemBackground
        
        // ナビゲーションバーの設定
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )
        
        // テーブルビューの設定
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ConnectionCell")
        view.addSubview(tableView)
    }
    
    private func loadConnections() {
        connections = RDPConnectionManager.shared.connections
        tableView.reloadData()
    }
    
    @objc private func addButtonTapped() {
        let addConnectionVC = AddConnectionViewController()
        let navigationController = UINavigationController(rootViewController: addConnectionVC)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
}

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
        // TODO: 接続処理の実装
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let connection = connections[indexPath.row]
            RDPConnectionManager.shared.deleteConnection(withId: connection.id)
            loadConnections()
        }
    }
} 