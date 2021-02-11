public struct FrontbaseRow: CustomStringConvertible {
    internal let data: [FrontbaseColumn: FrontbaseData]

    public var description: String {
        return self.data.mapValues { $0.description }.description
    }

    public func column (_ name: String) -> FrontbaseData? {
        guard let column = self.data.keys.first (where: { $0.name == name }) else {
            return nil
        }
        return data[column]
    }

    public func firstValue (forColumn name: String, inTable table: String? = nil) -> FrontbaseData? {
        for (col, val) in self.data {
            if (col.table == nil || table == nil || col.table == table) && col.name == name {
                return val
            }
        }
        return nil
    }

    public var allColumns: [String] {
        return self.data.keys.map { $0.name }
    }
}
