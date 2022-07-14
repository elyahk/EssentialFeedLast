import Cocoa

var greeting = "Hello, playground"

var someOptional: Int? = nil

// Match using an enumeration case pattern.
if case .some(let x) = someOptional {
    print(x)
}

someOptional = 43

// Match using an enumeration case pattern.
if case .some(let x) = someOptional {
    print(x)
}

extension String {
    // Overload the ~= operator to match a string with an integer.
    static func == (pattern: String, value: Int) -> Bool {
        return pattern == "\(value)"
    }
}

var string = "100"
var int = 100
print(string == int)

