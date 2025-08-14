//
//  Reusable.swift
//  PerfectKitchen
//
//  Created by 陈炼 on 2025/8/9.
//

import Foundation
import UIKit

// MARK: - Reusable

protocol Reusable: AnyObject {}

extension Reusable where Self: UIView {
    static var reuseIdentifier: String { String(describing: self) }
}

//MARK: - UICollectionViewCell+Reusable

extension UICollectionViewCell: Reusable {}

// MARK: - UICollectionView

extension UICollectionView {

    func register<T: UICollectionViewCell>(_ type: T.Type) {
        register(T.self, forCellWithReuseIdentifier: T.reuseIdentifier)
    }

    func register<T: UIView>(_: T.Type, forSupplementaryViewOfKind kind: String) where T: Reusable {
        register(T.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: T.reuseIdentifier)
    }

    func dequeueReusableCell<T: UICollectionViewCell>(for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.reuseIdentifier)")
        }
        return cell
    }

    func dequeueReusableSupplementaryView<T: UIView>(ofKind kind: String, for indexPath: IndexPath) -> T where T: Reusable {
        guard let view = dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: T.reuseIdentifier,
            for: indexPath
        ) as? T else {
            fatalError("Could not dequeue supplementary view of kind: \(kind) with identifier: \(T.reuseIdentifier)")
        }
        return view
    }
}

//MARK: - UITableViewCell+Reusable

extension UITableViewCell: Reusable {}

// MARK: - UITableView

extension UITableView {

    func register<T: UITableViewCell>(_ type: T.Type) {
        register(T.self, forCellReuseIdentifier: T.reuseIdentifier)
    }

    func registerHeaderFooterView<T: UIView>(_: T.Type) where T: Reusable {
        register(T.self, forHeaderFooterViewReuseIdentifier: T.reuseIdentifier)
    }

    func dequeueReusableCell<T: UITableViewCell>(for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.reuseIdentifier)")
        }
        return cell
    }

    func dequeueReusableHeaderFooterView<T: UIView>() -> T where T: Reusable {
        guard let headerFooterView = dequeueReusableHeaderFooterView(withIdentifier: T.reuseIdentifier) as? T else {
            fatalError("Could not dequeue header/footer with identifier: \(T.reuseIdentifier)")
        }
        return headerFooterView
    }
}
