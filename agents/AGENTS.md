In case I ever forget to put this descriptor on top of commited code files,
please draft something in this format (adapt the same format for other
language comment formats as well) and remind me.
```
# =============================================================================
# <filename>.<language_extension> — <description>
#
# More details about the file and it's role in the codebase.
#
# Copyright (c) <year> Temesgen Ataro <my set github email for the repo I'm in>
# SPDX-License-Identifier: Apache-2.0
# =============================================================================

```

In any and all code commits you make, never attribute your own name/company
affiliation as Claude. Ensure you only note that AI/agentic AI use was involved
in the development of the commit for XYZ reasons and assign attributions to
Tal'kamar Deshrel <tal@kamar.com> if necessary.

Follow this style when working on code:
- Implement one feature at a time and commit your change in communicable
English clean of abstract, multi-clause sentences. After you finish all your
work, be sure to ask whether your commits and your workflow were to the user's
liking.
For each commit diff, do a two-pass review:
Pass 1: structural review
- Does this belong?
- Is this design necessary?
- Did scope expand?
- Did complexity increase? Was it necessary?
- Can anything be deleted?
Pass 2: Correctness
- Boundary conditions
- Error handling
- State transitions
- Concurrency
- Ownership/lifetimes
- API assumptions
- Numerical behavior
- Tests

- Unless explicitly ordered to make code more professional and production grade
checks and error handling like below (Unless explicitly stated that code is
going to be used in production, assume research grade code is enough). Prefer
assertions or simply try/except blocks when you think they're necessary. Don't
hesitate to raise errors when you need to, just make sure they're absolutely necessary.

```python
# BAD!
def _load_script(path: Path):
    spec = importlib.util.spec_from_file_location("test_script", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    if not hasattr(module, "run"):
        raise AttributeError(f"{path} must define an async 'run(cfg, orch)' function")
    return module

```

```python
# BETTER
def load_script(path):  # This should really be under a utils.py file.
    """
    Loads a script, makes sure it defines an async 'run(cfg, orch)' function.
    """

    spec.importlib.util.spec_from_file_location("test_script", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    assert hasattr(module, "run"), f"{path} doesn't define an async 'run(cfg, orch)' function"

    return module
```

- Don't add type hints unless you truly sense ambiguity could arise.
- Prefer simplicity to more abstract approaches. Follow YAGNI and DRY
principles whenever you implement features.
- Prefer functional programming to OOP whenever possible.
- Limit your verbosity in responses and format your answers for an ADHD friendly
audience. Periodically perform a simplification pass after a few commits to do
the following:
_Do not add functionality._
Find:
    - dead code
    - unused wrappers
    - single-use abstractions
    - redundant configuration
    - duplicate helpers
    - obsolete compatibility paths
    - unnecessary dependency layers

Prefer deletion and inlining.
*Do not redesign the system.*
Then put your architecture into writing in an `ARCHITECTURE.md` document.
- No speculative abstraction without a concrete purpose. Prefer functions to
factories, handlers, managers, base classes, configs, helpers, etc. Make and
use a `utils.*` file to keep common, self-explaining functions you think make
the code more readable while not introducing congnitive overload for a
reviewer.
All of these rules are open to interpretation and as such shouldn't be followed
blindly, ask for clarification and justify your reasoning when you think is
appropriate.
