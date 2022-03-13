import Foundation

extension Collection {
    func sorted<Value: Comparable>(by property: (Element) -> Value) -> [Element] {
        sorted(by: property, order: <)
    }

    func sorted<Value: Comparable>(by property: (Element) -> Value, order: (Value, Value) -> Bool) -> [Element] {
        sorted { one, two in
            order(property(one), property(two))
        }
    }
}
