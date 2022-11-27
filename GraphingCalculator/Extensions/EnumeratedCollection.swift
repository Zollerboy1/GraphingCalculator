//
//  EnumeratedCollection.swift
//  GraphingCalculator
//
//  Created by Josef Zoller on 14.01.22.
//

@frozen
public struct EnumeratedCollection<Base: Collection> {
    @usableFromInline
    internal var _base: Base
    
    /// Construct from a `Base` sequence.
    @inlinable
    internal init(_base: Base) {
        self._base = _base
    }
}

extension EnumeratedCollection {
    /// The iterator for `EnumeratedCollection`.
    ///
    /// An instance of this iterator wraps a base iterator and yields
    /// successive `Int` values, starting at zero, along with the elements of the
    /// underlying base iterator. The following example enumerates the elements of
    /// an array:
    ///
    ///     var iterator = ["foo", "bar"].enumerated().makeIterator()
    ///     iterator.next() // (0, "foo")
    ///     iterator.next() // (1, "bar")
    ///     iterator.next() // nil
    ///
    /// To create an instance, call
    /// `enumerated().makeIterator()` on a sequence or collection.
    @frozen
    public struct Iterator {
        @usableFromInline
        internal var _base: Base.Iterator
        @usableFromInline
        internal var _count: Int
        
        /// Construct from a `Base` iterator.
        @inlinable
        internal init(_base: Base.Iterator) {
            self._base = _base
            self._count = 0
        }
    }
}

extension EnumeratedCollection.Iterator: IteratorProtocol, Sequence {
    /// The type of element returned by `next()`.
    public typealias Element = (offset: Int, element: Base.Element)
    
    /// Advances to the next element and returns it, or `nil` if no next element
    /// exists.
    ///
    /// Once `nil` has been returned, all subsequent calls return `nil`.
    @inlinable
    public mutating func next() -> Element? {
        guard let b = self._base.next() else { return nil }
        let result = (offset: _count, element: b)
        self._count += 1
        return result
    }
}

extension EnumeratedCollection: Sequence {
    /// Returns an iterator over the elements of this sequence.
    @inlinable
    public __consuming func makeIterator() -> Iterator {
        return Iterator(_base: _base.makeIterator())
    }
}

extension EnumeratedCollection: Collection {
    @frozen
    public struct Index {
        /// The position in the underlying collection.
        public let base: Base.Index
        
        /// The offset corresponding to this index when `base` is not the end index,
        /// `0` otherwise.
        @usableFromInline
        internal let offset: Int
        
        @inlinable
        internal init(base: Base.Index, offset: Int) {
            self.base = base
            self.offset = offset
        }
    }
    
    @inlinable
    public var startIndex: Index {
        return Index(base: self._base.startIndex, offset: 0)
    }
    
    @inlinable
    public var endIndex: Index {
        return Index(base: self._base.endIndex, offset: 0)
    }
    
    /// Returns the offset corresponding to `index`.
    ///
    /// - Complexity: O(*n*) if `index == endIndex` and `Base` does not conform to
    ///   `RandomAccessCollection`, O(1) otherwise.
    @inlinable
    internal func _offset(of index: Index) -> Int {
        return index.base == self._base.endIndex ? self._base.count : index.offset
    }
    
    @inlinable
    public func index(after index: Index) -> Index {
        precondition(index.base != self._base.endIndex, "Cannot advance past endIndex")
        return Index(base: self._base.index(after: index.base), offset: index.offset + 1)
    }
    
    @inlinable
    public subscript(position: Index) -> Element {
        (position.offset, self._base[position.base])
    }
    
    @inlinable
    public func index(_ i: Index, offsetBy distance: Int) -> Index {
        let index = self._base.index(i.base, offsetBy: distance)
        let offset = distance >= 0 ? i.offset : self._offset(of: i)
        return Index(base: index, offset: offset + distance)
    }
    
    @inlinable
    public func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
        guard let index = self._base.index(i.base, offsetBy: distance, limitedBy: limit.base) else {
            return nil
        }
        
        let offset = distance >= 0 ? i.offset : self._offset(of: i)
        return Index(base: index, offset: offset + distance)
    }
    
    @inlinable
    public func distance(from start: Index, to end: Index) -> Int {
        if start.base == self._base.endIndex || end.base == self._base.endIndex {
            return self._base.distance(from: start.base, to: end.base)
        } else {
            return end.offset - start.offset
        }
    }
    
    @inlinable
    public var count: Int {
        return self._base.count
    }
    
    @inlinable
    public var isEmpty: Bool {
        return self._base.isEmpty
    }
}

extension EnumeratedCollection: BidirectionalCollection where Base: BidirectionalCollection {
    @inlinable
    public func index(before index: Index) -> Index {
        return Index(base: self._base.index(before: index.base), offset: self._offset(of: index) - 1)
    }
}

extension EnumeratedCollection: RandomAccessCollection where Base: RandomAccessCollection {}

extension EnumeratedCollection: LazySequenceProtocol where Base: LazySequenceProtocol {}

extension EnumeratedCollection: LazyCollectionProtocol where Base: LazyCollectionProtocol {}

extension EnumeratedCollection.Index: Comparable {
    @inlinable
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.base == rhs.base
    }
    
    @inlinable
    public static func <(lhs: Self, rhs: Self) -> Bool {
        return lhs.base < rhs.base
    }
}


extension Collection {
    /// Returns a collection of pairs (*n*, *x*), where *n* represents a
    /// consecutive integer starting at zero and *x* represents an element of
    /// the sequence.
    ///
    /// This example enumerates the characters of the string "Swift" and prints
    /// each character along with its place in the string.
    ///
    ///     for (n, c) in "Swift".enumerated() {
    ///         print("\(n): '\(c)'")
    ///     }
    ///     // Prints "0: 'S'"
    ///     // Prints "1: 'w'"
    ///     // Prints "2: 'i'"
    ///     // Prints "3: 'f'"
    ///     // Prints "4: 't'"
    ///
    /// When you enumerate a collection, the integer part of each pair is a counter
    /// for the enumeration, but is not necessarily the index of the paired value.
    /// These counters can be used as indices only in instances of zero-based,
    /// integer-indexed collections, such as `Array` and `ContiguousArray`. For
    /// other collections the counters may be out of range or of the wrong type
    /// to use as an index. To iterate over the elements of a collection with its
    /// indices, use the `zip(_:_:)` function.
    ///
    /// This example iterates over the indices and elements of a set, building a
    /// list consisting of indices of names with five or fewer letters.
    ///
    ///     let names: Set = ["Sofia", "Camilla", "Martina", "Mateo", "Nicolás"]
    ///     var shorterIndices: [Set<String>.Index] = []
    ///     for (i, name) in zip(names.indices, names) {
    ///         if name.count <= 5 {
    ///             shorterIndices.append(i)
    ///         }
    ///     }
    ///
    /// Now that the `shorterIndices` array holds the indices of the shorter
    /// names in the `names` set, you can use those indices to access elements in
    /// the set.
    ///
    ///     for i in shorterIndices {
    ///         print(names[i])
    ///     }
    ///     // Prints "Sofia"
    ///     // Prints "Mateo"
    ///
    /// - Returns: A collection of pairs enumerating the collection.
    ///
    /// - Complexity: O(1)
    @inlinable // protocol-only
    public func enumerated() -> EnumeratedCollection<Self> {
        return EnumeratedCollection(_base: self)
    }
}
