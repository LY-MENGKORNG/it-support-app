/// WARN: Class modifiers control how a class or `mixin` can be used, both from within its own library, and from outside the library where it's defined.
///
/// NOTE: Modifier keywords come before a class or mixin declaration.
/// For example, writing abstract class defines an abstract class.
/// The full set of modifiers that can appear before a class declaration include:
///
/// - abstract
/// - base
/// - final
/// - interface
/// - sealed
/// - mixin
///
/// NOTE: Only the base modifier can appear before a mixin declaration.
/// The modifiers do not apply to other declarations like `enum`, `typedef`, `extension`, or `extension type`.

library;

/// WARN: To allow unrestricted permission to construct or subtype from any library,
/// use a class or mixin declaration without a modifier. By default, you can:
///
/// - Construct new instances of a class.
/// - Extend a class to create a new subtype.
/// - Implement a class or mixin's interface.
/// - Mix in a mixin or mixin class.
class NoModifier {}

/// NOTE: To define a class that doesn't require a full, concrete implementation of its entire interface, use the abstract modifier.
///
/// Abstract classes cannot be constructed from any library,
/// whether its own or an outside library.
/// Abstract classes often have abstract methods.
abstract class AbstractModifier {}

base class BaseModifier {}

final class FinalModifier {}

interface class InterfaceModifier {}

sealed class SealedModifier {}

mixin class MixinModifier {}
