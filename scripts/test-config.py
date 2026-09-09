"""Exercise configuration scripts without touching the real home directory."""
import os
from pathlib import Path
import subprocess
import tempfile

SCRIPTS = Path(__file__).resolve().parent

with tempfile.TemporaryDirectory(prefix="dotfiles test ") as temporary:
    home = Path(temporary)
    env = dict(os.environ, DOTFILES_HOME=str(home))
    targets = [home / ".zshrc", home / ".config/starship.toml", home / ".tmux.conf"]
    names = ["zshrc", "starship.toml", "tmux.conf"]
    backups = home / ".local/state/dotfiles/backups"

    def run(script, *args, success=True):
        result = subprocess.run([str(SCRIPTS / script), *args], cwd="/", env=env,
                                text=True, capture_output=True)
        assert (result.returncode == 0) == success, result.stdout + result.stderr
        return result.stdout

    for target, name in zip(targets, names):
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("original " + name)
    run("sync.sh")
    first = next(backups.iterdir())
    for target, name in zip(targets, names):
        assert target.is_symlink()
        assert (first / name).read_text() == "original " + name
    run("sync.sh")
    assert len(list(backups.iterdir())) == 1, "Sync must be idempotent"
    assert first.name in run("restore.sh", "--list")
    linked_contents = [p.read_bytes() for p in targets]
    run("restore.sh", first.name)
    second = next(p for p in backups.iterdir() if p != first)
    for target, name, content in zip(targets, names, linked_contents):
        assert not target.is_symlink()
        assert target.read_text() == "original " + name
        assert (second / name).read_bytes() == content
        assert not (second / name).is_symlink(), "Backup must snapshot symlink contents"
    run("restore.sh", second.name)
    assert [p.read_bytes() for p in targets] == linked_contents
    assert len(list(backups.iterdir())) == 3, "Rapid backups must not collide"
    run("restore.sh", "../escape", success=False)
    run("restore.sh", "missing", success=False)
    # A directory at any target must abort before other targets change.
    targets[2].unlink()
    targets[2].mkdir()
    before = targets[0].read_bytes()
    run("sync.sh", success=False)
    assert targets[0].read_bytes() == before and not targets[0].is_symlink()
    run("restore.sh", first.name, success=False)
    targets[2].rmdir()
    # Preserve and restore dangling links; tolerate absent targets.
    targets[0].unlink()
    targets[0].symlink_to(home / "missing-source")
    existing = set(backups.iterdir())
    run("sync.sh")
    partial = (set(backups.iterdir()) - existing).pop()
    assert not (partial / "tmux.conf").exists()
    run("restore.sh", partial.name)
    assert targets[0].is_symlink() and os.readlink(targets[0]) == str(home / "missing-source")
    assert targets[2].is_symlink(), "Files absent from backup must stay untouched"
print("Backup/restore checks passed")

# Exercise failures through stub executables, without network or live home writes.
for scenario in ["blocked-parent", "restore-copy", "sync-rename", "restore-rename", "absent-rollback", "download"]:
    with tempfile.TemporaryDirectory(prefix="dotfiles failure ") as temporary:
        home = Path(temporary)
        targets = [home / ".zshrc", home / ".config/starship.toml", home / ".tmux.conf"]
        for target in targets:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("original " + target.name)
        fake = home / "bin"
        fake.mkdir()
        env = dict(os.environ, DOTFILES_HOME=str(home), PATH=str(fake) + ":" + os.environ["PATH"])

        def stub(name, body):
            path = fake / name
            path.write_text("#!/bin/bash\n" + body)
            path.chmod(0o755)

        def state():
            return [("link", os.readlink(p)) if p.is_symlink() else
                    ("file", p.read_bytes()) if p.exists() else ("absent", None)
                    for p in targets]

        command = [str(SCRIPTS / "sync.sh")]
        if scenario.startswith("restore"):
            subprocess.run(command, env=env, cwd="/", check=True, capture_output=True)
            snapshot = next((home / ".local/state/dotfiles/backups").iterdir())
            command = [str(SCRIPTS / "restore.sh"), snapshot.name]
        if scenario == "blocked-parent":
            targets[1].unlink()
            targets[1].parent.rmdir()
            targets[1].parent.write_text("obstruction")
        elif scenario == "restore-copy":
            stub("cp", 'case "${@: -1}" in */replacement) exit 1;; esac\nexec /bin/cp "$@"\n')
        elif scenario in ["sync-rename", "restore-rename", "absent-rollback"]:
            if scenario == "absent-rollback":
                targets[0].unlink()
            stub("mv", 'if [[ "$2" == */replacement && "$3" == */starship.toml ]]; then exit 1; fi\nexec /bin/mv "$@"\n')
        elif scenario == "download":
            stub("curl", 'printf "called\\n" >> "$DOTFILES_HOME/curl-calls"\nexit 22\n')
            command = [str(SCRIPTS.parent / "setup.sh")]
        before = state()
        result = subprocess.run(command, env=env, cwd="/", capture_output=True, text=True)
        assert result.returncode != 0, (scenario, result.stdout, result.stderr)
        assert state() == before, (scenario, "Active files changed on failure")
        assert not list(home.rglob(".dotfiles-stage.*")), (scenario, "Staging files leaked")
        if scenario == "download":
            assert (home / "curl-calls").read_text() == "called\n", "Setup continued after failed download"
print("Failure regression checks passed")
