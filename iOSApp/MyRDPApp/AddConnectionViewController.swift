import Foundation
import UIKit

class AddConnectionViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: - Outlets
    @IBOutlet weak private var nameTextField: UITextField! {
        didSet {
            nameTextField.delegate = self
        }
    }
    @IBOutlet weak private var hostTextField: UITextField!
    {
        didSet {
            hostTextField.delegate = self
        }
    }
    @IBOutlet weak private var portTextField: UITextField!
    {
        didSet {
            portTextField.delegate = self
        }
    }
    @IBOutlet weak private var usernameTextField: UITextField!
    {
        didSet {
            usernameTextField.delegate = self
        }
    }
    @IBOutlet weak private var passwordTextField: UITextField!
    {
        didSet {
            passwordTextField.delegate = self
        }
    }
    @IBOutlet weak private var scrollView: UIScrollView!
    @IBOutlet weak private var contentView: UIView!
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardHandling()
    }
    
    // MARK: - Setup Methods
        
    private func setupUI() {
        title = "新規接続先"
        view.backgroundColor = .systemBackground
    }
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        // タップでキーボードを閉じる
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        // スクロールビューの調整
        scrollView.contentInset.bottom = keyboardFrame.height
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardFrame.height
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        // スクロールビューの調整
        scrollView.contentInset.bottom = 0
        scrollView.horizontalScrollIndicatorInsets.bottom = 0
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Actions
    
    @IBAction func cancelButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func saveButtonTapped() {
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
            password: passwordTextField.text
        )
        
        RDPConnectionManager.shared.addConnection(connection)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension AddConnectionViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case nameTextField:
            hostTextField.becomeFirstResponder()
        case hostTextField:
            portTextField.becomeFirstResponder()
        case portTextField:
            usernameTextField.becomeFirstResponder()
        case usernameTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            textField.resignFirstResponder()
            saveButtonTapped()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
}
