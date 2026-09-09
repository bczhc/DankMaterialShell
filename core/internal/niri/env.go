// Package niri provides helpers for reading niri's KDL configuration.
package niri

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/sblinch/kdl-go"
	"github.com/sblinch/kdl-go/document"
	"github.com/sblinch/kdl-go/relaxed"
)

// EnvVar is a single environment variable read from a niri `environment` block.
type EnvVar struct {
	Key   string
	Value string
}

// DefaultConfigPath returns the path to niri's main config file, honoring the
// same discovery rules as niri itself: the NIRI_CONFIG environment variable
// takes precedence, otherwise $XDG_CONFIG_HOME/niri/config.kdl is used.
func DefaultConfigPath() string {
	if cfg := os.Getenv("NIRI_CONFIG"); cfg != "" {
		return cfg
	}
	configDir, err := os.UserConfigDir()
	if err != nil {
		return ""
	}
	return filepath.Join(configDir, "niri", "config.kdl")
}

// ParseEnvironment parses niri's config.kdl (following `include` directives) and
// returns the merged environment variables from all `environment` blocks, in the
// order they were first defined. Later definitions of the same key win.
func ParseEnvironment(configPath string) ([]EnvVar, error) {
	p := &envParser{
		vars:  make(map[string]string),
		stack: make(map[string]bool),
	}
	if err := p.parseFile(configPath); err != nil {
		return nil, err
	}

	vars := make([]EnvVar, 0, len(p.order))
	for _, key := range p.order {
		vars = append(vars, EnvVar{Key: key, Value: p.vars[key]})
	}
	return vars, nil
}

type envParser struct {
	vars  map[string]string
	order []string
	// stack tracks the files currently being parsed, to break include cycles.
	stack map[string]bool
}

// parseDoc parses a KDL document using relaxed syntax, matching the extensions
// niri itself accepts (for example identifiers that begin with an underscore,
// such as __GL_SHADER_DISK_CACHE_SIZE).
func parseDoc(r io.Reader) (*document.Document, error) {
	return kdl.ParseWithOptions(r, kdl.ParseOptions{RelaxedNonCompliant: relaxed.NGINXSyntax})
}

func (p *envParser) parseFile(path string) error {
	abs, err := filepath.Abs(path)
	if err != nil {
		return fmt.Errorf("resolve path %s: %w", path, err)
	}

	if p.stack[abs] {
		return nil
	}
	p.stack[abs] = true
	defer delete(p.stack, abs)

	data, err := os.ReadFile(abs)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return fmt.Errorf("read %s: %w", abs, err)
	}

	doc, err := parseDoc(strings.NewReader(string(data)))
	if err != nil {
		return fmt.Errorf("parse KDL %s: %w", abs, err)
	}

	baseDir := filepath.Dir(abs)
	for _, node := range doc.Nodes {
		p.processNode(node, baseDir)
	}
	return nil
}

func (p *envParser) processNode(node *document.Node, baseDir string) {
	switch node.Name.String() {
	case "include":
		if len(node.Arguments) == 0 {
			return
		}
		includePath := node.Arguments[0].ValueString()
		if !filepath.IsAbs(includePath) {
			includePath = filepath.Join(baseDir, includePath)
		}
		_ = p.parseFile(includePath)
	case "environment":
		p.extractEnvironment(node)
	}
}

func (p *envParser) extractEnvironment(node *document.Node) {
	for _, child := range node.Children {
		key := child.Name.String()
		if key == "" {
			continue
		}

		var value string
		if len(child.Arguments) > 0 {
			value = child.Arguments[0].ValueString()
		}

		if _, exists := p.vars[key]; !exists {
			p.order = append(p.order, key)
		}
		p.vars[key] = value
	}
}
