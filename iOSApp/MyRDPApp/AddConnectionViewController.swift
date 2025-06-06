import UIKit

class AddConnectionViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let nameTextField = UITextField()
    private let hostTextField = UITextField()
    private let portTextField = UITextField()
    private let usernameTextField = UITextField()
    private let passwordTextField = UITextField()
    private let domainTextField = UITextField()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "新規接続先"
        view.backgroundColor = .systemBackground
        
        // ナビゲーションバーの設定
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelButtonTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveButtonTapped)
        )
        
        // スクロールビューの設定
        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scrollView)
        
        contentView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 600)
        scrollView.addSubview(contentView)
        scrollView.contentSize = contentView.frame.size
        
        // テキストフィールドの設定
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        // 各テキストフィールドの設定
        nameTextField.placeholder = "接続名"
        hostTextField.placeholder = "ホスト名またはIPアドレス"
        portTextField.placeholder = "ポート番号（デフォルト: 3389）"
        usernameTextField.placeholder = "ユーザー名"
        passwordTextField.placeholder = "パスワード"
        passwordTextField.isSecureTextEntry = true
        domainTextField.placeholder = "ドメイン（オプション）"
        
        [nameTextField, hostTextField, portTextField, usernameTextField, passwordTextField, domainTextField].forEach { textField in
            textField.borderStyle = .roundedRect
            stackView.addArrangedSubview(textField)
        }
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveButtonTapped() {
        guard let name = nameTextField.text, !name.isEmpty,
              let host = hostTextField.text, !host.isEmpty,
              let username = usernameTextField.text, !username.isEmpty else {
            // エラー表示
            let alert = UIAlertController(
                title: "エラー",
                message: "必須項目を入力してください",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let port = Int(portTextField.text ?? "") ?? 3389
        let connection = RDPConnection(
            name: name,
            host: host,
            port: port,
            username: username,
            password: passwordTextField.text,
            domain: domainTextField.text
        )
        
        RDPConnectionManager.shared.addConnection(connection)
        dismiss(animated: true)
    }
} 