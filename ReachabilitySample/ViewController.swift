//
//  ViewController.swift
//  ReachabilitySample
//
//  Created by Bing Guo on 2023/1/15.
//

import UIKit

class ViewController: UIViewController {
    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.alignment = .center
        view.distribution = .fillProportionally
        view.spacing = 12
        return view
    }()
    lazy var wifiView: ItemView = {
        let view = ItemView(frame: .zero, title: "WiFi", imageName: "wifi")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    lazy var cellularView: ItemView = {
        let view = ItemView(frame: .zero, title: "Cellular", imageName: "antenna.radiowaves.left.and.right")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    lazy var unreachableView: ItemView = {
        let view = ItemView(frame: .zero, title: "No Connect", imageName: "xmark.octagon")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()

        NotificationCenter.default.addObserver(self, selector: #selector(networkStatusChanged), name: .networkStatusChanged, object: nil)

        setupNetworkStatusUI(NetworkStatus.shared.status)
    }

    @objc func networkStatusChanged(_ notification: Notification) {
        guard let networkStatus = notification.object as? NetworkStatus else { return }
        setupNetworkStatusUI(networkStatus.status)
    }

    private func setupNetworkStatusUI(_ status: NetworkStatus.InterfaceType) {
        wifiView.setEnable(false)
        cellularView.setEnable(false)
        unreachableView.setEnable(false)
        switch status {
        case .unknown:
            unreachableView.setEnable(true)
        case .wifi:
            wifiView.setEnable(true)
        case .cellular:
            cellularView.setEnable(true)
        }
    }
}

private extension ViewController {
    func setupUI() {
        view.backgroundColor = .white

        view.addSubview(stackView)
        stackView.addArrangedSubview(wifiView)
        stackView.addArrangedSubview(cellularView)
        stackView.addArrangedSubview(unreachableView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.widthAnchor.constraint(equalToConstant: 200),
        ])
    }
}

class ItemView: UIView {
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 24)
        return label
    }()

    init(frame: CGRect, title: String, imageName: String) {
        super.init(frame: frame)

        imageView.image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .gray
        titleLabel.text = title
        titleLabel.textColor = .gray

        addSubview(imageView)
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 32),
            imageView.heightAnchor.constraint(equalToConstant: 32),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setEnable(_ value: Bool) {
        DispatchQueue.main.async {
            self.imageView.tintColor = value ? .blue : .gray
            self.titleLabel.textColor = value ? .blue : .gray
        }
    }
}
