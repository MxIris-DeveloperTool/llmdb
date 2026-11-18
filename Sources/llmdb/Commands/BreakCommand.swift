import ArgumentParser
import Foundation

struct BreakCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "break",
        abstract: "Manage breakpoints",
        subcommands: [SetSub.self, FunctionSub.self, ListSub.self, DeleteSub.self, ExceptionSub.self]
    )

    struct SetSub: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "set",
            abstract: "Set a breakpoint by file:line"
        )

        @Argument(help: "Location: `<file>:<line>`")
        var location: String

        @Option(name: .long, help: "Session ID")
        var session: String?

        @Option(name: .long, help: "Fire only when this expression is true, e.g. `n > 100`")
        var condition: String?

        @Option(name: .long, help: "Fire on a hit-count match, e.g. `>5` or `3`")
        var hitCondition: String?

        func run() async throws {
            let (file, line) = try parseFileLineLocation(location)
            let result = try await DaemonClient.call(
                RPC.breakSet,
                BreakSetParams(
                    sessionId: session,
                    file: file,
                    line: line,
                    condition: condition,
                    hitCondition: hitCondition
                )
            )
            try JSONOutput.print(result)
        }
    }

    struct FunctionSub: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "function",
            abstract: "Set a breakpoint on a function by name (works without debug info)"
        )

        // Captured verbatim so an Objective-C instance method's leading `-`
        // isn't read as an option; see `passthroughText`. Everything from the
        // name on belongs to it, so llmdb's own options must come first.
        @Argument(
            parsing: .captureForPassthrough,
            help: "Swift (`compute`, `Module.Type.method`), C, or Objective-C name. Put options first; precede a `-[…]` name with `--`, e.g. `-- '-[NSWindow makeFirstResponder:]'`."
        )
        var nameWords: [String] = []

        @Option(name: .long, help: "Session ID")
        var session: String?

        @Option(name: .long, help: "Fire only when this expression is true, e.g. `n > 100`")
        var condition: String?

        @Option(name: .long, help: "Fire on a hit-count match, e.g. `>5` or `3`")
        var hitCondition: String?

        func validate() throws {
            guard passthroughText(nameWords) != nil else {
                throw ValidationError("Missing expected argument '<name>'")
            }
        }

        func run() async throws {
            let result = try await DaemonClient.call(
                RPC.breakFunction,
                BreakFunctionParams(
                    sessionId: session,
                    name: passthroughText(nameWords) ?? "",
                    condition: condition,
                    hitCondition: hitCondition
                )
            )
            try JSONOutput.print(result)
        }
    }

    struct ListSub: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "list",
            abstract: "List breakpoints in a session"
        )

        @Option(name: .long, help: "Session ID")
        var session: String?

        func run() async throws {
            let result = try await DaemonClient.call(
                RPC.breakList,
                SessionParams(sessionId: session)
            )
            try JSONOutput.print(result)
        }
    }

    struct DeleteSub: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "delete",
            abstract: "Delete a breakpoint by ID; returns the remaining breakpoints"
        )

        @Argument(help: "Breakpoint ID")
        var id: Int

        @Option(name: .long, help: "Session ID")
        var session: String?

        func run() async throws {
            let result = try await DaemonClient.call(
                RPC.breakDelete,
                BreakDeleteParams(sessionId: session, id: id)
            )
            try JSONOutput.print(result)
        }
    }

    struct ExceptionSub: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "exception",
            abstract: "Stop on thrown exceptions; pass filter ids to enable, none to clear"
        )

        @Argument(help: "Filter ids to enable (e.g. swift_throw). Omit to clear and list what's available.")
        var filters: [String] = []

        @Option(name: .long, help: "Session ID")
        var session: String?

        func run() async throws {
            let result = try await DaemonClient.call(
                RPC.breakException,
                BreakExceptionParams(sessionId: session, filters: filters)
            )
            try JSONOutput.print(result)
        }
    }
}
