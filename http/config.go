package http

type Config struct {
	Host      string   `json:"host"`
	Enabled   bool     `json:"enabled"`
	Default   bool     `json:"default"`
	RulesFile []string `json:"rulesFile"`
}
