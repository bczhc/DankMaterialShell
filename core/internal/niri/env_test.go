package niri

import (
	"os"
	"path/filepath"
	"testing"
)

func TestParseEnvironment(t *testing.T) {
	dir := t.TempDir()

	writeFile := func(rel, content string) {
		t.Helper()
		path := filepath.Join(dir, rel)
		if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
			t.Fatalf("mkdir: %v", err)
		}
		if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
			t.Fatalf("write: %v", err)
		}
	}

	writeFile("config.kdl", `
environment {
    XMODIFIERS "@im=fcitx"
    QT_IM_MODULES "wayland;fcitx"
    XDG_CURRENT_DESKTOP "niri"
    __GL_SHADER_DISK_CACHE_SIZE "100000000000"
}
include "sub/extra.kdl"
environment {
    XDG_CURRENT_DESKTOP "niri:GNOME"
}
`)
	writeFile("sub/extra.kdl", `
environment {
    GDK_BACKEND "wayland"
}
`)

	vars, err := ParseEnvironment(filepath.Join(dir, "config.kdl"))
	if err != nil {
		t.Fatalf("ParseEnvironment: %v", err)
	}

	got := make(map[string]string, len(vars))
	for _, v := range vars {
		got[v.Key] = v.Value
	}

	want := map[string]string{
		"XMODIFIERS":                  "@im=fcitx",
		"QT_IM_MODULES":               "wayland;fcitx",
		"XDG_CURRENT_DESKTOP":         "niri:GNOME", // last definition wins
		"GDK_BACKEND":                 "wayland",
		"__GL_SHADER_DISK_CACHE_SIZE": "100000000000",
	}
	if len(got) != len(want) {
		t.Fatalf("got %d vars %v, want %d", len(got), got, len(want))
	}
	for k, v := range want {
		if got[k] != v {
			t.Errorf("env[%q] = %q, want %q", k, got[k], v)
		}
	}
}

func TestParseEnvironmentMissingFile(t *testing.T) {
	vars, err := ParseEnvironment(filepath.Join(t.TempDir(), "does-not-exist.kdl"))
	if err != nil {
		t.Fatalf("ParseEnvironment: %v", err)
	}
	if len(vars) != 0 {
		t.Fatalf("expected no vars, got %v", vars)
	}
}

func TestParseEnvironmentIncludeCycle(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "config.kdl")
	content := `
include "a.kdl"
environment {
    CYCLE_TEST "ok"
}
`
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatalf("write: %v", err)
	}
	if err := os.WriteFile(filepath.Join(dir, "a.kdl"), []byte(`include "config.kdl"`), 0o644); err != nil {
		t.Fatalf("write: %v", err)
	}

	vars, err := ParseEnvironment(path)
	if err != nil {
		t.Fatalf("ParseEnvironment: %v", err)
	}
	if len(vars) != 1 || vars[0].Key != "CYCLE_TEST" || vars[0].Value != "ok" {
		t.Fatalf("unexpected vars: %v", vars)
	}
}
