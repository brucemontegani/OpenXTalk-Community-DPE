# OpenXTalk Engine Codebase Cartographer

## Table of Contents
1. [Concept → Code Map](#1-concept--code-map)
2. [Walk the Code Storyline](#2-walk-the-code-storyline)
3. [Glossary of Core Runtime Structures](#3-glossary-of-core-runtime-structures)
4. [2-Week Learning Plan](#4-2-week-learning-plan)
5. [Questions to Ask the Repo Checklist](#5-questions-to-ask-the-repo-checklist)

---

## 1. Concept → Code Map

### A. Script Loading / Script Storage

| Aspect | Location | Key Types/Functions | Notes |
|--------|----------|---------------------|-------|
| Script text storage | `engine/src/object.h` | `MCObject::hlist` (MCHandlerlist*) | Scripts are stored per-object |
| Handler list | `engine/src/hndlrlst.h` | `MCHandlerlist`, `MCHandlerArray` | Indexed by handler type |
| Script compilation | `engine/src/handler.cpp` | `MCHandler::parse()` | Parses script text into statements |
| Script property | `engine/src/object.h:749-750` | `sendgetprop()`, `sendsetprop()` | "script" property access |

**Data Flow**: Object script property → `MCHandlerlist::parse()` → `MCHandler` linked list

---

### B. Parsing (Tokenizer/Lexer + Grammar + AST)

| Aspect | Location | Key Types/Functions | Notes |
|--------|----------|---------------------|-------|
| **LiveCode Script Lexer** | `engine/src/scriptpt.h` | `MCScriptPoint` class (256 lines) | Main tokenizer |
| Symbol types | `engine/src/parsedef.h` | `Symbol_type` enum (ST_ID, ST_NUM, ST_OP, etc.) | 17+ symbol types |
| Token types | `engine/src/parsedef.h` | `Token_type` enum (TT_HANDLER, TT_STATEMENT, TT_FUNCTION, etc.) | Token classification |
| Lexical tables | `engine/src/lextable.cpp` | Character classification, keyword tables | Symbol lookup |
| **LCB Grammar** | `toolchain/lc-compile/src/grammar.g` | Gentle parser generator format (46KB) | Main grammar |
| LCB Type checking | `toolchain/lc-compile/src/check.g` | Semantic analysis rules (75KB) | Type validation |
| LCB Code gen | `toolchain/lc-compile/src/generate.g` | Bytecode generation rules (82KB) | Emission rules |
| Statement parsing | `engine/src/statemnt.h` | `MCStatement::parse()` | Each statement type parses itself |

**Key Files for LCS Parsing**:
- `engine/src/parsedef.h` (2,349 lines) - Master definition of all syntax elements
- `engine/src/scriptpt.h` - Scanner/lexer implementation
- `engine/src/cmds.h` - Command parsing classes
- `engine/src/funcs.h` - Function parsing classes

**Key Files for LCB Parsing**:
- `toolchain/lc-compile/src/grammar.g` - Main grammar
- `toolchain/lc-compile/src/syntax.g` - Syntax definition rules
- `toolchain/lc-compile/src/bind.g` - Module binding/imports

---

### C. Compilation (Bytecode / IR / Symbol Tables)

| Aspect | Location | Key Types/Functions | Notes |
|--------|----------|---------------------|-------|
| **LCS: Statement-based** | `engine/src/statemnt.h` | `MCStatement` linked list | No bytecode - direct interpretation |
| Handler storage | `engine/src/handler.h` | `MCHandler::statements` | Statement chains |
| **LCB Bytecode** | `libscript/src/script-bytecode.hpp` | `MCScriptBytecodeOp*` classes (1,046 lines) | 50+ instruction types |
| Bytecode emission | `toolchain/lc-compile/src/emit.cpp` | `EmitStart()`, `EmitBeginOpcode()`, etc. (2,613 lines) | Code generation |
| Module format | `libscript/src/script-private.h` | `MCScriptModule` struct | Compiled module representation |
| Definition types | `libscript/src/script-private.h` | `MCScriptDefinition`, `MCScriptHandlerDefinition` | Symbol table entries |
| Constant pool | `libscript/src/script-private.h` | `MCValueRef *values` in `MCScriptModule` | Literal storage |

**Bytecode Format Parameters**:
- `r` - register (parameter, local, temp)
- `c` - constant pool index
- `d` - fetchable definition
- `h` - handler definition
- `l` - label/jump address

**Key Bytecode Instructions**:
- `Jump`, `JumpIfTrue`, `JumpIfFalse` - Control flow
- `Assign`, `AssignConstant` - Value assignment
- `Invoke`, `InvokeIndirect` - Handler calls
- `Fetch`, `Store` - Variable access
- `Return` - Handler exit

---

### D. Execution (VM/Interpreter Loop, Call Frames, Variables)

| Aspect | Location | Key Types/Functions | Notes |
|--------|----------|---------------------|-------|
| **LCS Execution Context** | `engine/src/exec-context.h` | `MCExecContext` class (431 lines) | State, errors, formatting |
| Execution value | `engine/src/exec.h` | `MCExecValue` union, `MCExecValueType` enum | Runtime values |
| Statement execution | `engine/src/statemnt.cpp:59` | `MCStatement::exec_ctxt()` | Virtual dispatch |
| Handler execution | `engine/src/handler.cpp:321` | `MCHandler::exec()` | Entry point |
| **LCB VM** | `libscript/src/script-execute.hpp` | `MCScriptExecuteContext` class | Bytecode interpreter |
| LCB execution | `libscript/src/script-execute.cpp` | `Execute()` dispatch loop | Main loop |
| **Variables** | `engine/src/variable.h` | `MCVariable` class (500 lines) | Name, value, flags |
| Variable reference | `engine/src/variable.h:338` | `MCVarref` class | Handles arrays, chunks |
| Container | `engine/src/variable.h` | `MCContainer` class | Indirect access |
| Handler locals | `engine/src/handler.h` | `MCHandler::vars`, `MCHandlerVarInfo` | Local scope |
| Globals | `engine/src/handler.h` | `MCHandler::globals`, `MCVariable::lookupglobal()` | Global scope |

**Execution Status Values** (`Exec_stat`):
- `ES_NORMAL` - Continue execution
- `ES_ERROR` - Error occurred
- `ES_RETURN_HANDLER` - Return from handler
- `ES_EXIT_REPEAT` - Break from repeat loop
- `ES_NEXT_REPEAT` - Continue to next iteration
- `ES_PASS` - Pass message up hierarchy

---

### E. Built-in Commands/Functions Registration

| Aspect | Location | Key Types/Functions | Notes |
|--------|----------|---------------------|-------|
| Statement types | `engine/src/parsedef.h` | `Statement_type` (S_* enums) | 130+ statements |
| Function types | `engine/src/parsedef.h` | `Functions` (F_* enums) | 300+ functions |
| Command classes | `engine/src/cmds.h` | `MC*Cmd` classes (700+ lines) | 40+ command types |
| Function classes | `engine/src/funcs.h` | `MC*Function` classes (2,700+ lines) | 100+ function types |
| **Implementation files** | `engine/src/exec-*.cpp` | 60+ files | Actual implementations |
| Type system | `engine/src/exec.h` | `MCExecType` enum, conversion functions (4,452 lines) | Type handling |

**Key exec-*.cpp Files by Domain**:
- `exec-strings*.cpp` - String manipulation (5+ files)
- `exec-arrays.cpp` - Array operations
- `exec-math.cpp` - Mathematical functions
- `exec-files.cpp` - File I/O
- `exec-network.cpp` - Network operations
- `exec-interface-*.cpp` - UI commands (20+ files)
- `exec-graphics.cpp` - Graphics commands
- `exec-multimedia.cpp` - Audio/video

---

### F. Message Dispatch (send/post, Event Queue, Bubbling)

| Aspect | Location | Key Types/Functions | Notes |
|--------|----------|---------------------|-------|
| Global dispatcher | `engine/src/dispatch.h` | `MCDispatch` class (319 lines) | Root message router |
| Object handler | `engine/src/object.h:704` | `MCObject::handle()` | Per-object dispatch |
| Handler lookup | `engine/src/hndlrlst.h` | `MCHandlerArray::find()` | O(log n) binary search |
| Handler types | `engine/src/parsedef.h` | `Handler_type` enum | HT_MESSAGE, HT_FUNCTION, etc. |
| Send message | `engine/src/object.h:1029` | `MCObject::sendmessage()` | Send to self |
| Execute handler | `engine/src/object.h:1061` | `MCObject::exechandler()` | Direct execution |
| Parent script | `engine/src/object.h:1067` | `MCObject::execparenthandler()` | Behavior inheritance |

**Handler Types**:
- `HT_MESSAGE` - Message handlers (on mouseUp, etc.)
- `HT_FUNCTION` - Custom functions
- `HT_GETPROP` - Property getters (getProp)
- `HT_SETPROP` - Property setters (setProp)
- `HT_BEFORE` - Before handlers
- `HT_AFTER` - After handlers

**Message Path**: Target → Card → Stack → mainStack → homeStack → MCDispatch

---

### G. Object Model (Stack/Card/Control Hierarchy, Properties)

| Aspect | Location | Key Types/Functions | Notes |
|--------|----------|---------------------|-------|
| Base object | `engine/src/object.h` | `MCObject` class (1,730+ lines) | All objects inherit |
| Stack | `engine/src/stack.h` | `MCStack` class (500+ lines) | Window container |
| Card | `engine/src/card.h` | `MCCard` class (400+ lines) | Page within stack |
| Control base | `engine/src/mccontrol.h` | `MCControl` class (600+ lines) | UI element base |
| Field | `engine/src/field.h` | `MCField` class | Text fields |
| Button | `engine/src/button.h` | `MCButton` class | Buttons |
| Image | `engine/src/image.h` | `MCImage` class | Images |
| Group | `engine/src/group.h` | `MCGroup` class | Container groups |
| Widget | `engine/src/widget.h` | `MCWidget` class | LCB widgets |
| **Property tables** | `engine/src/exec.h` | `MCPropertyInfo`, `MCObjectPropertyTable` | Property registration |
| Object visitor | `engine/src/object.h` | `MCObjectVisitor` struct | Tree traversal |
| Object proxy | `engine/src/object.h` | `MCObjectProxy<T>` | Weak references |

**Object Hierarchy**:
```
MCObject (base)
├── MCStack (window)
│   ├── cards: MCCard* (linked list)
│   ├── controls: MCControl* (stack-level)
│   └── substacks: MCStack* (nested stacks)
├── MCCard (page)
│   └── objptrs: MCObjptr* (references to controls)
└── MCControl (UI element)
    ├── MCField (text)
    ├── MCButton (button)
    ├── MCImage (image)
    ├── MCGroup (container)
    ├── MCScrollbar
    ├── MCGraphic
    ├── MCPlayer
    └── MCWidget (LCB widget)
```

---

### H. Error Reporting (Syntax/Runtime, Stack Traces)

| Aspect | Location | Key Types/Functions | Notes |
|--------|----------|---------------------|-------|
| Execution errors | `engine/src/exec-context.h` | `MCExecContext::Throw()`, `HasError()` | Runtime errors |
| Error state | `engine/src/exec-context.h` | `MCExecContext::m_stat` | Status tracking |
| Legacy errors | `engine/src/exec-context.h` | `LegacyThrow()` | Old-style errors |
| Parse errors | `engine/src/parsedef.h` | `Parse_stat` enum | PS_ERROR, PS_BREAK, etc. |
| Line tracking | `engine/src/statemnt.h` | `MCStatement::line`, `pos` | Source position |
| Handler lines | `engine/src/handler.h` | `MCHandler::firstline`, `lastline` | Handler span |
| **LCB errors** | `libscript/src/script-error.cpp` | Script error handling | LCB-specific |
| Compiler errors | `toolchain/libcompile/report.h` | Error/diagnostic reporting | Compilation errors |

---

### I. Host Integration (Platform UI, Rendering, System Calls)

| Aspect | Location | Key Types/Functions | Notes |
|--------|----------|---------------------|-------|
| **Platform abstraction** | `engine/src/platform.h` | Platform interface | Cross-platform API |
| macOS | `engine/src/mac-*.cpp` | Platform-specific impl | 50+ files |
| Windows | `engine/src/w32*.cpp` | Windows impl | win32 API |
| Linux | `engine/src/lnx*.cpp` | Linux impl | X11/GTK |
| Unix common | `engine/src/sysunx*.cpp` | POSIX common | Shared Unix code |
| Mobile | `engine/src/mbl*.cpp` | iOS/Android common | Mobile abstractions |
| **Graphics** | `libgraphics/` | Rendering library | Skia-based |
| Foundation | `libfoundation/` | Core types, strings | Base library |

**Platform File Prefixes**:
- `mac-` - macOS specific
- `w32` - Windows specific
- `lnx` - Linux specific
- `sysunx` - Unix shared (macOS + Linux)
- `mbl` - Mobile (iOS + Android)
- `srv` - Server engine

---

### J. Testing Harnesses

| Aspect | Location | Key Types/Functions | Notes |
|--------|----------|---------------------|-------|
| LCS tests | `tests/lcs/` | `.livecodescript` files | Test* handlers |
| LCB tests | `tests/lcb/stdlib/`, `tests/lcb/vm/` | `.lcb` files | LCB unit tests |
| Compiler tests | `tests/lcb/compiler/frontend/` | `.compilertest` files | %TEST/%EXPECT directives |
| C++ tests | `libfoundation/test/`, `engine/test/` | Google Test | libcpptest framework |
| Test library | `tests/_testlib.livecodescript` | `TestAssert`, `TestSkip`, `TestDiagnostic` | LCS test framework |
| Test runner | `tests/_testrunner.livecodescript` | Test orchestration | Runs test suites |

---

## 2. Walk the Code Storyline

### "User types a script and it runs" - Complete Path

#### Step 1: Script Text Entry
**Files**: `engine/src/object.h`, `engine/src/field.h`
- User edits script in IDE script editor (a field control)
- When applying/saving, the "script" property of the object is set
- **Entry**: `MCObject::setprop()` → script property setter

#### Step 2: Script Parsing Begins
**Files**: `engine/src/scriptpt.h`, `engine/src/parsedef.h`
```
MCHandlerlist::parse(MCScriptPoint& sp)
├── MCScriptPoint initialized with script text
├── sp.token() loops through tokens
│   ├── Character classification via lextable
│   ├── Symbol_type determination (ST_ID, ST_NUM, etc.)
│   └── Token_type assignment (TT_HANDLER, TT_STATEMENT, etc.)
└── Creates MCHandler for each handler block
```

#### Step 3: Handler Parsing
**Files**: `engine/src/handler.h`, `engine/src/handler.cpp`
```
MCHandler::parse(MCScriptPoint& sp)
├── Parse handler name and parameters
├── Loop: parse statements until "end <handlername>"
│   ├── MCStatement subclass created based on keyword
│   ├── statement->parse(sp) parses operands
│   └── Statement linked into chain
├── Store local variable declarations
└── Handler added to MCHandlerArray (sorted for binary search)
```

#### Step 4: Statement Parsing
**Files**: `engine/src/cmds.h`, `engine/src/funcs.h`
```
MCPut::parse(MCScriptPoint& sp)     // Example: "put x into y"
├── Parse source expression
│   └── MCExpression tree built
├── Parse preposition ("into", "after", "before")
└── Parse destination (MCChunk or MCVarref)
```

#### Step 5: Message Dispatch (Runtime)
**Files**: `engine/src/dispatch.cpp`, `engine/src/object.cpp`
```
User clicks button → platform event → MCDispatch
├── MCDispatch::handle(HT_MESSAGE, "mouseUp", params, button)
├── Message path traversal:
│   ├── MCButton::handle() → check for handler
│   ├── MCCard::handle() → check for handler
│   ├── MCStack::handle() → check for handler
│   └── Continue up hierarchy until handled
└── Found: MCHandlerArray::find("mouseUp")
```

#### Step 6: Handler Execution
**Files**: `engine/src/handler.cpp:321`, `engine/src/exec-context.h`
```
MCHandler::exec(MCExecContext& ctxt, MCParameter* params)
├── Set up local variables
├── Bind parameters to locals
├── Loop through statement chain:
│   while (statement != nullptr) {
│     statement->exec_ctxt(ctxt);
│     if (ctxt.HasError()) break;
│     statement = statement->next();
│   }
└── Clean up locals, return Exec_stat
```

#### Step 7: Statement Execution
**Files**: `engine/src/exec-*.cpp` (60+ files)
```
MCPut::exec_ctxt(MCExecContext& ctxt)
├── Evaluate source expression
│   └── MCExpression::eval_ctxt(ctxt, value)
├── Resolve destination
│   └── MCChunk or MCVarref resolution
├── Call builtin implementation
│   └── MCStringsExecPutIntoVariable(ctxt, value, dest)
└── Check/propagate errors
```

#### Step 8: Expression Evaluation
**Files**: `engine/src/express.h`, `engine/src/funcs.h`
```
MCConcat::eval_ctxt(ctxt, result)   // Example: "a & b"
├── left->eval_ctxt(ctxt, left_val)
├── right->eval_ctxt(ctxt, right_val)
├── MCStringsExecConcatenate(ctxt, left_val, right_val, result)
└── Return result through MCExecValue
```

#### Step 9: Built-in Function Call
**Files**: `engine/src/funcs.h`, `engine/src/exec-strings.cpp`
```
MCLength::eval_ctxt(ctxt, result)   // Example: length("hello")
├── Evaluate parameter expression
├── MCStringsEvalLengthOf(ctxt, string, result)
│   └── result = MCStringGetLength(string)
└── Return result
```

---

## 3. Glossary of Core Runtime Structures

### Parsing Structures

| Structure | Purpose | Location |
|-----------|---------|----------|
| `MCScriptPoint` | Lexer/scanner that produces tokens from script text | `engine/src/scriptpt.h` |
| `Symbol_type` | Basic token categories (ID, NUM, OP, EOF, etc.) | `engine/src/parsedef.h` |
| `Token_type` | Semantic token types (HANDLER, STATEMENT, FUNCTION, etc.) | `engine/src/parsedef.h` |
| `Parse_stat` | Parser return status (PS_NORMAL, PS_ERROR, PS_BREAK) | `engine/src/parsedef.h` |

### Compilation Structures (LCB)

| Structure | Purpose | Location |
|-----------|---------|----------|
| `MCScriptModule` | Compiled module containing bytecode, types, definitions | `libscript/src/script-private.h` |
| `MCScriptDefinition` | Base for all definitions (handlers, variables, types) | `libscript/src/script-private.h` |
| `MCScriptHandlerDefinition` | Handler with local vars, bytecode address range | `libscript/src/script-private.h` |
| `MCScriptBytecodeOp*` | Bytecode instruction classes (50+) | `libscript/src/script-bytecode.hpp` |

### Execution Structures

| Structure | Purpose | Location |
|-----------|---------|----------|
| `MCExecContext` | Execution state: errors, formatting, delimiters | `engine/src/exec-context.h` |
| `MCExecValue` | Union type holding runtime values (refs, primitives) | `engine/src/exec.h` |
| `MCExecValueType` | Discriminator for MCExecValue union | `engine/src/exec.h` |
| `Exec_stat` | Execution status (ES_NORMAL, ES_ERROR, ES_RETURN, etc.) | `engine/src/parsedef.h` |
| `MCScriptExecuteContext` | LCB VM execution context | `libscript/src/script-execute.hpp` |

### Handler Structures

| Structure | Purpose | Location |
|-----------|---------|----------|
| `MCHandler` | Handler containing statements, locals, parameters | `engine/src/handler.h` |
| `MCHandlerlist` | Container for all handlers of an object | `engine/src/hndlrlst.h` |
| `MCHandlerArray` | Sorted array of handlers for O(log n) lookup | `engine/src/hndlrlst.h` |
| `Handler_type` | Handler category (MESSAGE, FUNCTION, GETPROP, etc.) | `engine/src/parsedef.h` |
| `MCHandlerVarInfo` | Local variable name and initializer | `engine/src/handler.h` |
| `MCHandlerParamInfo` | Parameter name and by-reference flag | `engine/src/handler.h` |

### Statement/Expression Structures

| Structure | Purpose | Location |
|-----------|---------|----------|
| `MCStatement` | Base class for executable statements | `engine/src/statemnt.h` |
| `MCExpression` | Base class for evaluable expressions | `engine/src/express.h` |
| `MCChunk` | Chunk expression (word 1 of field "x") | `engine/src/chunk.h` |
| `MCParameter` | Function/handler parameter wrapper | `engine/src/param.h` |

### Variable Structures

| Structure | Purpose | Location |
|-----------|---------|----------|
| `MCVariable` | Named variable with value and flags | `engine/src/variable.h` |
| `MCVarref` | Variable reference expression (supports arrays) | `engine/src/variable.h` |
| `MCContainer` | Indirect variable access (for by-reference params) | `engine/src/variable.h` |

### Object Structures

| Structure | Purpose | Location |
|-----------|---------|----------|
| `MCObject` | Base class for all objects | `engine/src/object.h` |
| `MCStack` | Top-level window container | `engine/src/stack.h` |
| `MCCard` | Card within a stack | `engine/src/card.h` |
| `MCControl` | Base for UI controls | `engine/src/mccontrol.h` |
| `MCField`, `MCButton`, `MCImage`, etc. | Specific control types | `engine/src/field.h`, etc. |
| `MCDispatch` | Global message dispatcher | `engine/src/dispatch.h` |
| `MCObjectVisitor` | Visitor pattern for object traversal | `engine/src/object.h` |
| `MCObjectProxy<T>` | Weak reference handle to objects | `engine/src/object.h` |

### Property Structures

| Structure | Purpose | Location |
|-----------|---------|----------|
| `MCPropertyInfo` | Property metadata (name, type, getter/setter) | `engine/src/exec.h` |
| `MCObjectPropertyTable` | Table of properties with inheritance | `engine/src/exec.h` |
| `MCExecType` | Property/parameter type codes | `engine/src/exec.h` |

---

## 4. 2-Week Learning Plan

### Week 1: Foundation & Core Concepts

#### Day 1-2: Project Structure & Build System
**Goal**: Understand the codebase layout and build process

**Files to read**:
- `README.md`, `CLAUDE.md` - Project overview
- `Makefile`, `livecode.gyp` - Build configuration
- Top-level directory structure

**Tasks**:
- Build the project: `make config-mac && make compile-mac`
- Open Xcode project: `open build-mac-debug/OpenXTalk.xcodeproj`
- Identify the four engine flavors (development, standalone, server, installer)

**Checkpoint**: You can build and run the IDE

---

#### Day 3-4: Object Model Basics
**Goal**: Understand the object hierarchy

**Files to read**:
- `engine/src/object.h` (focus on first 500 lines)
- `engine/src/stack.h` (first 200 lines)
- `engine/src/card.h` (first 150 lines)
- `engine/src/mccontrol.h` (first 200 lines)

**Tasks**:
- Trace inheritance: MCObject → MCStack, MCCard, MCControl
- Find where `obj_id`, `name`, `hlist` are defined
- Understand `MCObjectVisitor` pattern

**Checkpoint**: You can explain the Stack → Card → Control hierarchy

---

#### Day 5: Variable System
**Goal**: Understand variable storage and scoping

**Files to read**:
- `engine/src/variable.h` (complete file)
- `engine/src/handler.h` (focus on var-related members)

**Tasks**:
- Trace MCVariable: name, value, flags
- Understand local vs global scope management
- Find `MCVariable::lookupglobal()`

**Checkpoint**: You can trace how `put "hello" into x` stores the value

---

#### Day 6-7: Parsing Fundamentals
**Goal**: Understand tokenization and statement parsing

**Files to read**:
- `engine/src/scriptpt.h` (complete file)
- `engine/src/parsedef.h` (browse Symbol_type, Token_type, Statement_type)
- `engine/src/lextable.cpp` (skim for structure)

**Tasks**:
- Trace `MCScriptPoint::token()` flow
- Identify how keywords are recognized
- Find the statement type enum entries

**Checkpoint**: You can explain how "put" becomes a TT_STATEMENT

---

### Week 2: Execution & Advanced Topics

#### Day 8-9: Handler Structure & Execution
**Goal**: Understand handler parsing and execution

**Files to read**:
- `engine/src/handler.h` (complete file)
- `engine/src/handler.cpp` (focus on `parse()` and `exec()`)
- `engine/src/hndlrlst.h` (complete file)

**Tasks**:
- Trace `MCHandler::parse()` - how statements are chained
- Trace `MCHandler::exec()` - the statement execution loop
- Understand handler lookup via `MCHandlerArray::find()`

**Checkpoint**: You can trace a "on mouseUp / end mouseUp" handler from parse to execution

---

#### Day 10: Statement Execution
**Goal**: Understand how specific statements execute

**Files to read**:
- `engine/src/statemnt.h` (complete file)
- `engine/src/cmds.h` (browse first 300 lines)
- `engine/src/exec-strings.cpp` (pick one function to trace)

**Tasks**:
- Trace `MCPut` from `cmds.h` to its `exec_ctxt()` implementation
- Follow through to the actual `MCStringsExec*` function

**Checkpoint**: You can trace "put x into y" from statement to execution

---

#### Day 11: Message Dispatch
**Goal**: Understand message passing

**Files to read**:
- `engine/src/dispatch.h` (complete file)
- `engine/src/dispatch.cpp` (focus on `handle()`)
- `engine/src/object.h` (find `handle()`, `sendmessage()`)

**Tasks**:
- Trace a mouseUp message from dispatch to handler
- Understand the message path (target → card → stack)
- Find where "pass" is implemented

**Checkpoint**: You can explain how clicking a button runs its mouseUp handler

---

#### Day 12: Expression Evaluation
**Goal**: Understand expression trees

**Files to read**:
- `engine/src/express.h` (complete file)
- `engine/src/funcs.h` (browse, pick 2-3 functions)
- `engine/src/exec-math.cpp` (pick one function)

**Tasks**:
- Trace `MCExpression::eval_ctxt()` virtual dispatch
- Follow a function like `length()` from `funcs.h` to implementation
- Understand MCExecValue return mechanism

**Checkpoint**: You can trace "length(x) + 1" evaluation

---

#### Day 13: Property System
**Goal**: Understand property get/set

**Files to read**:
- `engine/src/exec.h` (focus on MCPropertyInfo, MCObjectPropertyTable)
- `engine/src/object.h` (find property table reference)
- One `exec-interface-*.cpp` file

**Tasks**:
- Find how "the width of button 1" resolves
- Trace property table inheritance
- Understand getter/setter function pointers

**Checkpoint**: You can trace "set the width of button 1 to 100"

---

#### Day 14: LCB Bytecode (Optional Advanced)
**Goal**: Understand the LCB compilation model

**Files to read**:
- `libscript/src/script-private.h` (module structure)
- `libscript/src/script-bytecode.hpp` (instruction classes)
- `libscript/src/script-execute.cpp` (execution loop)

**Tasks**:
- Compare LCS (statement chain) vs LCB (bytecode) execution
- Trace MCScriptModule structure
- Find the main execution loop

**Checkpoint**: You understand the two execution models (LCS interpretation vs LCB bytecode)

---

## 5. Questions to Ask the Repo Checklist

### Parsing & Compilation

| Search | Command | What It Reveals |
|--------|---------|-----------------|
| Token types | `grep -r "Symbol_type" engine/src/ --include="*.h"` | Lexer symbol definitions |
| Statement types | `grep -r "enum.*Statement" engine/src/parsedef.h` | All statement keywords |
| Function types | `grep -r "enum.*Functions" engine/src/parsedef.h` | All built-in functions |
| Parser entry | `grep -r "MCScriptPoint::token" engine/src/` | Tokenizer implementation |
| Statement parse | `grep -r "Parse_stat.*parse" engine/src/*.h` | Statement parsing methods |

### Execution

| Search | Command | What It Reveals |
|--------|---------|-----------------|
| Execution loop | `grep -r "exec_ctxt" engine/src/statemnt` | Statement execution entry |
| Handler exec | `grep -rn "MCHandler::exec" engine/src/` | Handler execution |
| Exec status | `grep -r "Exec_stat" engine/src/parsedef.h` | Return status values |
| Error handling | `grep -r "HasError\|Throw" engine/src/exec-context` | Error mechanism |

### Message Dispatch

| Search | Command | What It Reveals |
|--------|---------|-----------------|
| Handle method | `grep -rn "::handle(" engine/src/*.cpp` | Message handling implementations |
| Send message | `grep -r "sendmessage\|send(" engine/src/object` | Message sending |
| Dispatch | `grep -r "MCDispatch" engine/src/dispatch` | Global dispatcher |
| Handler lookup | `grep -r "findhandler\|find(" engine/src/hndlrlst` | Handler resolution |

### Object Model

| Search | Command | What It Reveals |
|--------|---------|-----------------|
| Object types | `grep -r "CT_STACK\|CT_CARD\|CT_CONTROL" engine/src/` | Object type constants |
| Property tables | `grep -r "kProperties\[\]" engine/src/` | Property definitions |
| Object hierarchy | `grep -r "class MC.*: public MCObject" engine/src/` | Inheritance |

### Built-ins

| Search | Command | What It Reveals |
|--------|---------|-----------------|
| Command impl | `ls engine/src/exec-*.cpp` | Builtin implementation files |
| String functions | `grep -r "MCStringsEval\|MCStringsExec" engine/src/` | String operations |
| Math functions | `grep -r "MCMathEval\|MCMathExec" engine/src/` | Math operations |

### Variables

| Search | Command | What It Reveals |
|--------|---------|-----------------|
| Variable class | `grep -rn "class MCVariable" engine/src/variable.h` | Variable structure |
| Global lookup | `grep -r "lookupglobal\|ensureglobal" engine/src/` | Global access |
| Container | `grep -r "class MCContainer" engine/src/variable` | Indirect access |

### LCB Specifics

| Search | Command | What It Reveals |
|--------|---------|-----------------|
| Bytecode ops | `grep -r "MCScriptBytecodeOp" libscript/src/` | Instruction set |
| Module structure | `grep -r "struct MCScriptModule" libscript/src/` | Compiled module format |
| Execution | `grep -r "Execute\|Invoke" libscript/src/script-execute` | VM loop |
| Emit functions | `grep -r "^void Emit" toolchain/lc-compile/src/emit.cpp` | Code generation |

---

## Quick Reference: Key Entry Points

| Task | File | Function/Line |
|------|------|---------------|
| Parse script | `handler.cpp` | `MCHandlerlist::parse()` |
| Execute handler | `handler.cpp:321` | `MCHandler::exec()` |
| Execute statement | `statemnt.cpp:59` | `MCStatement::exec_ctxt()` |
| Dispatch message | `dispatch.cpp` | `MCDispatch::handle()` |
| Look up handler | `hndlrlst.cpp` | `MCHandlerArray::find()` |
| Evaluate expression | `express.cpp` | `MCExpression::eval_ctxt()` |
| Get property | `object.cpp` | `MCObject::getprop()` |
| Set property | `object.cpp` | `MCObject::setprop()` |
| Tokenize | `scriptpt.cpp` | `MCScriptPoint::token()` |

---

## Notes & Assumptions

1. **Two Language Implementations**: OpenXTalk has two scripting languages:
   - **LiveCode Script (LCS)** - Traditional, interpreted via statement chains
   - **LiveCode Builder (LCB)** - Modern, compiled to bytecode

2. **No AST for LCS**: LiveCode Script parsing directly creates executable `MCStatement` chains rather than an intermediate AST. Each statement type (`MCPut`, `MCIf`, `MCRepeat`) parses its own syntax.

3. **Handler Types**: The 6 handler types (message, function, getprop, setprop, before, after) are stored in separate sorted arrays for fast lookup.

4. **Property Tables**: Properties use a table-driven system with inheritance, allowing efficient property lookup and type conversion.

5. **Platform Abstraction**: Platform-specific code is segregated by file prefix (`mac-`, `w32`, `lnx`, `mbl`) rather than preprocessor conditionals where possible.

---

*Generated for OpenXTalk Community Edition codebase exploration*
