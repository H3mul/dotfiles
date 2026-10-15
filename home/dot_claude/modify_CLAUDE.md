{{- /* chezmoi:modify-template */ -}}
{{- $base := includeTemplate ".claude/CLAUDE.md" | trim -}}
{{- $existing := .chezmoi.stdin -}}
{{- if contains $base $existing -}}
    {{- $existing -}}
{{- else if eq ($existing | trim) "" -}}
    {{- $base }}
{{ else -}}
    {{- $existing | trimSuffix "\n" }}

{{ $base }}
{{ end -}}
