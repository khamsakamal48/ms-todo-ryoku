# mstodo

Tiny Microsoft To Do CLI (Python standard library only) behind the `ms-todo`
and `ms-todo-desk` Ryoku plugins. Run `./mstodo` with no arguments for usage.

    install -m 755 mstodo ~/.local/bin/mstodo
    mstodo setup --client-id <Entra app id> --tenant <tenant id>
    mstodo login      # device code; or use the plugin's Sign in button
