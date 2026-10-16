import Foundation

/// Pip's face expression. It is decided in the core from the arbitrated
/// reaction so the view only has to render it: a tap (`.click`) makes Pip happy
/// and open its mouth; everything else is neutral.
public enum PipExpression: String, CaseIterable, Equatable, Sendable {
    case neutral
    case happy
}

extension ReactionEmission {
    /// The expression the arbitrated reaction implies this frame.
    public var expression: PipExpression {
        reaction == .click ? .happy : .neutral
    }
}
