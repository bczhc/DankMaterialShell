package main

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/AvengeMedia/DankMaterialShell/core/internal/log"
	"github.com/AvengeMedia/DankMaterialShell/core/internal/niri"
	"github.com/spf13/cobra"
)

var (
	envConfigPath string
	envJSON       bool
)

var envCmd = &cobra.Command{
	Use:   "env",
	Short: "Print environment variables from niri's config",
	Long: `Parse niri's config.kdl (following include directives) and print the
environment variables defined in "environment" blocks.

By default each variable is printed as KEY=VALUE. Use --json to print a JSON
object, which is easier for scripts and the shell to consume.`,
	Run: func(cmd *cobra.Command, args []string) {
		configPath := envConfigPath
		if configPath == "" {
			configPath = niri.DefaultConfigPath()
		}

		vars, err := niri.ParseEnvironment(configPath)
		if err != nil {
			log.Fatalf("failed to parse niri environment: %v", err)
		}

		if envJSON {
			obj := make(map[string]string, len(vars))
			for _, v := range vars {
				obj[v.Key] = v.Value
			}
			if err := json.NewEncoder(os.Stdout).Encode(obj); err != nil {
				log.Fatalf("failed to encode environment: %v", err)
			}
			return
		}

		for _, v := range vars {
			fmt.Printf("%s=%s\n", v.Key, v.Value)
		}
	},
}

func init() {
	envCmd.Flags().StringVarP(&envConfigPath, "config", "c", "", "Path to the niri config file (default: $NIRI_CONFIG or $XDG_CONFIG_HOME/niri/config.kdl)")
	envCmd.Flags().BoolVar(&envJSON, "json", false, "Print the environment as a JSON object")
}
