#!/bin/bash

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_usage() {
  cat <<'EOF'
Usage: run.sh <command>

Commands:
  prepare   Check environment and bootstrap Blitz
  discover  Detect project, scheme, and related metadata
  test      Inspect or run meaningful existing tests
  blitz     Execute Blitz-driven app flow
  report    Print the latest unified report
  run       Execute the full end-to-end workflow
  help      Show this help text
EOF
}

lookup_path() {
  printf '%s\n' "${BLITZ_LOOKUP_PATH:-$PATH}"
}

require_command() {
  local name="$1"

  if ! PATH="$(lookup_path)" command -v "$name" >/dev/null 2>&1; then
    echo "Missing required command: $name" >&2
    return 1
  fi
}

check_simctl() {
  if ! PATH="$(lookup_path)" xcrun simctl help >/dev/null 2>&1; then
    echo "Missing required command: simctl" >&2
    return 1
  fi
}

install_blitz() {
  cat >&2 <<'EOF'
Blitz is not installed.
Install Blitz from the official website or the official GitHub repository, then retry:
- https://blitz.dev
- https://github.com/blitzdotdev/blitz-mac
EOF
  return 1
}

ensure_blitz() {
  if PATH="$(lookup_path)" command -v blitz >/dev/null 2>&1; then
    return 0
  fi

  install_blitz || return 1
}

prepare_environment() {
  require_command node
  require_command npm
  require_command xcodebuild
  require_command xcrun
  check_simctl
  ensure_blitz
  echo "Environment ready"
}

trim_value() {
  local value="$1"
  value="${value#${value%%[!$' \t\r\n']*}}"
  value="${value%${value##*[!$' \t\r\n']}}"
  printf '%s' "$value"
}

config_value() {
  local key="$1"
  local file="${2:-$PWD/codex.blitz.toml}"

  [[ -f "$file" ]] || return 1

  awk -v key="$key" '
    $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
      sub(/^[^=]*=[[:space:]]*/, "", $0)
      sub(/[[:space:]]*#.*$/, "", $0)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      if ($0 ~ /^".*"$/) {
        sub(/^"/, "", $0)
        sub(/"$/, "", $0)
      }
      print $0
      exit
    }
  ' "$file"
}

config_bool_enabled() {
  local key="$1"
  local raw=""
  raw="$(config_value "$key" || true)"

  case "$raw" in
    true|TRUE|True|1|yes|YES)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

existing_tests_policy() {
  local raw=""
  raw="$(config_value existing_tests_policy || true)"

  case "$raw" in
    run|skip|prompt)
      printf '%s\n' "$raw"
      ;;
    *)
      printf 'prompt\n'
      ;;
  esac
}

resolve_project_path() {
  local raw="$1"

  if [[ "$raw" = /* ]]; then
    printf '%s\n' "$raw"
  else
    printf '%s/%s\n' "$PWD" "$raw"
  fi
}

xcode_mcp_capability() {
  if [[ "${BLITZ_XCODE_MCP_AVAILABLE:-0}" == "1" ]]; then
    echo "available"
  elif PATH="$(lookup_path)" command -v xcode-mcp >/dev/null 2>&1; then
    echo "available"
  else
    echo "unavailable"
  fi
}

top_level_candidates() {
  find "$PWD" -mindepth 1 -maxdepth 2 -type d \( -name '*.xcworkspace' -o -name '*.xcodeproj' \) | sort
}

project_kind_for_path() {
  local path="$1"
  case "$path" in
    *.xcworkspace) echo "workspace" ;;
    *.xcodeproj) echo "project" ;;
    *) echo "unknown" ;;
  esac
}

discover_candidate_path() {
  local config_project=""
  local config_workspace=""
  local candidates=()
  local candidate=""

  config_project="$(config_value project_path || true)"
  config_workspace="$(config_value workspace_path || true)"

  if [[ -n "$config_workspace" ]]; then
    printf '%s\n' "$(resolve_project_path "$config_workspace")"
    return 0
  fi

  if [[ -n "$config_project" ]]; then
    printf '%s\n' "$(resolve_project_path "$config_project")"
    return 0
  fi

  while IFS= read -r candidate; do
    [[ -n "$candidate" ]] && candidates+=("$candidate")
  done < <(top_level_candidates)

  case "${#candidates[@]}" in
    0)
      echo "No iOS project or workspace found in $PWD" >&2
      return 1
      ;;
    1)
      printf '%s\n' "${candidates[0]}"
      return 0
      ;;
    *)
      echo "Ambiguous iOS project discovery: multiple candidates found" >&2
      printf '%s\n' "${candidates[@]}" >&2
      return 1
      ;;
  esac
}

discover_scheme_for_path() {
  local path="$1"
  local config_scheme=""
  local kind=""
  local output=""
  local scheme_lines=()
  local scheme_line=""

  config_scheme="$(config_value scheme || true)"
  if [[ -n "$config_scheme" ]]; then
    printf '%s\n' "$config_scheme"
    return 0
  fi

  kind="$(project_kind_for_path "$path")"
  case "$kind" in
    workspace)
      output="$(PATH="$(lookup_path)" xcodebuild -list -workspace "$path" 2>/dev/null)"
      ;;
    project)
      output="$(PATH="$(lookup_path)" xcodebuild -list -project "$path" 2>/dev/null)"
      ;;
    *)
      echo "Unsupported project kind for scheme discovery: $path" >&2
      return 1
      ;;
  esac

  while IFS= read -r scheme_line; do
    scheme_line="$(trim_value "$scheme_line")"
    [[ -n "$scheme_line" ]] && scheme_lines+=("$scheme_line")
  done < <(
    printf '%s\n' "$output" | awk '
      /^[[:space:]]*Schemes:/ { capture=1; next }
      capture {
        if ($0 ~ /^[[:space:]]*$/) {
          if (count > 0) exit
          next
        }
        if ($0 !~ /^[[:space:]]+/) exit
        print
        count++
      }
    '
  )

  case "${#scheme_lines[@]}" in
    0)
      echo "No schemes discovered for $path" >&2
      return 1
      ;;
    1)
      printf '%s\n' "${scheme_lines[0]}"
      return 0
      ;;
    *)
      echo "Ambiguous scheme discovery for $path" >&2
      printf '%s\n' "${scheme_lines[@]}" >&2
      return 1
      ;;
  esac
}

discover_command() {
  local selected_path=""
  local selected_kind=""
  local selected_scheme=""

  selected_path="$(discover_candidate_path)"
  if [[ ! -d "$selected_path" ]]; then
    echo "Configured or discovered project path does not exist: $selected_path" >&2
    return 1
  fi
  selected_kind="$(project_kind_for_path "$selected_path")"
  selected_scheme="$(discover_scheme_for_path "$selected_path")"

  printf 'project_path=%s\n' "$selected_path"
  printf 'project_kind=%s\n' "$selected_kind"
  printf 'scheme=%s\n' "$selected_scheme"
  printf 'xcode_mcp=%s\n' "$(xcode_mcp_capability)"
}

swift_test_files_in_dir() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  find "$dir" -type f -name '*.swift' | sort
}

classify_unit_test_dir() {
  local dir="$1"
  local files=""

  files="$(swift_test_files_in_dir "$dir")"
  [[ -n "$files" ]] || {
    echo "missing"
    return 0
  }

  if printf '%s\n' "$files" | xargs grep -Eq 'func test[[:alnum:]_]+' \
    && printf '%s\n' "$files" | xargs grep -Eq 'XCTAssert|#expect' \
    && ! printf '%s\n' "$files" | xargs grep -Eq 'func testExample|func testPerformanceExample'; then
    echo "meaningful"
    return 0
  fi

  if printf '%s\n' "$files" | xargs grep -Eq 'func testExample|func testPerformanceExample'; then
    echo "template-only"
    return 0
  fi

  echo "template-only"
}

classify_ui_test_dir() {
  local dir="$1"
  local files=""

  files="$(swift_test_files_in_dir "$dir")"
  [[ -n "$files" ]] || {
    echo "missing"
    return 0
  }

  if printf '%s\n' "$files" | xargs grep -Eq '\.tap\(|\.swipe(Up|Down|Left|Right)\(|buttons\[|cells\[|collectionViews\.' \
    && printf '%s\n' "$files" | xargs grep -Eq 'XCTAssert|waitForExistence|XCTNSPredicateExpectation'; then
    echo "meaningful"
    return 0
  fi

  if printf '%s\n' "$files" | xargs grep -Eq 'app\.launch\(\)|XCUIApplication\(\)|XCTAttachment\(screenshot:'; then
    echo "template-only"
    return 0
  fi

  echo "template-only"
}

list_targets_for_selection() {
  local path="$1"
  local kind="$2"
  local output=""

  case "$kind" in
    workspace)
      output="$(PATH="$(lookup_path)" xcodebuild -list -workspace "$path" 2>/dev/null)"
      ;;
    project)
      output="$(PATH="$(lookup_path)" xcodebuild -list -project "$path" 2>/dev/null)"
      ;;
    *)
      echo "Unsupported project kind for target discovery: $kind" >&2
      return 1
      ;;
  esac

  printf '%s\n' "$output" | awk '
    /^[[:space:]]*Targets:$/ { capture=1; next }
    capture {
      if ($0 ~ /^[[:space:]]*$/) {
        if (count > 0) exit
        next
      }
      if ($0 !~ /^[[:space:]]+/) exit
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      print
      count++
    }
  '
}

runner_simulator_name() {
  local configured=""
  configured="$(config_value simulator_name || true)"
  if [[ -n "$configured" ]]; then
    printf '%s\n' "$configured"
  else
    printf 'iPhone 17\n'
  fi
}

run_xcode_tests_for_target() {
  local path="$1"
  local kind="$2"
  local scheme="$3"
  local simulator="$4"
  local target="$5"

  case "$kind" in
    workspace)
      PATH="$(lookup_path)" xcodebuild test -workspace "$path" -scheme "$scheme" -destination "platform=iOS Simulator,name=$simulator" -only-testing:"$target" >/dev/null
      ;;
    project)
      PATH="$(lookup_path)" xcodebuild test -project "$path" -scheme "$scheme" -destination "platform=iOS Simulator,name=$simulator" -only-testing:"$target" >/dev/null
      ;;
    *)
      echo "Unsupported project kind for test execution: $kind" >&2
      return 1
      ;;
  esac
}

status_for_targets() {
  local kind="$1"
  local path="$2"
  local scheme="$3"
  local simulator="$4"
  local mode="$5"
  shift 5
  local targets=("$@")
  local target=""
  local dir=""
  local classification=""
  local saw_template=0

  for target in "${targets[@]}"; do
    [[ -n "$target" ]] || continue
    dir="$PWD/$target"
    if [[ "$mode" == "unit" ]]; then
      classification="$(classify_unit_test_dir "$dir")"
    else
      classification="$(classify_ui_test_dir "$dir")"
    fi

    case "$classification" in
      meaningful)
        if run_xcode_tests_for_target "$path" "$kind" "$scheme" "$simulator" "$target"; then
          echo "passed"
        else
          echo "failed"
        fi
        return 0
        ;;
      template-only)
        saw_template=1
        ;;
    esac
  done

  if [[ $saw_template -eq 1 ]]; then
    echo "skipped (template-only)"
  else
    echo "not-found"
  fi
}

detection_for_targets() {
  local mode="$1"
  shift
  local targets=("$@")
  local target=""
  local dir=""
  local classification=""
  local saw_template=0

  for target in "${targets[@]}"; do
    [[ -n "$target" ]] || continue
    dir="$PWD/$target"
    if [[ "$mode" == "unit" ]]; then
      classification="$(classify_unit_test_dir "$dir")"
    else
      classification="$(classify_ui_test_dir "$dir")"
    fi

    case "$classification" in
      meaningful)
        echo "meaningful"
        return 0
        ;;
      template-only)
        saw_template=1
        ;;
    esac
  done

  if [[ $saw_template -eq 1 ]]; then
    echo "template-only"
  else
    echo "not-found"
  fi
}

test_command() {
  local selected_path=""
  local selected_kind=""
  local selected_scheme=""
  local simulator=""
  local targets=()
  local target=""
  local unit_targets=()
  local ui_targets=()
  local unit_status=""
  local ui_status=""
  local unit_detection=""
  local ui_detection=""
  local policy=""

  selected_path="$(discover_candidate_path)"
  selected_kind="$(project_kind_for_path "$selected_path")"
  selected_scheme="$(discover_scheme_for_path "$selected_path")"
  simulator="$(runner_simulator_name)"
  policy="$(existing_tests_policy)"

  while IFS= read -r target; do
    [[ -n "$target" ]] || continue
    targets+=("$target")
  done < <(list_targets_for_selection "$selected_path" "$selected_kind")

  for target in "${targets[@]}"; do
    if [[ "$target" == *UITests ]]; then
      ui_targets+=("$target")
    elif [[ "$target" == *Tests ]]; then
      unit_targets+=("$target")
    fi
  done

  unit_detection="$(detection_for_targets unit "${unit_targets[@]}")"
  ui_detection="$(detection_for_targets ui "${ui_targets[@]}")"

  if config_bool_enabled skip_unit_tests; then
    unit_status="skipped (config)"
  elif [[ "$policy" == "skip" && "$unit_detection" == "meaningful" ]]; then
    unit_status="skipped (policy)"
  elif [[ "$policy" == "prompt" && "$unit_detection" == "meaningful" ]]; then
    unit_status="prompt-required"
  else
    unit_status="$(status_for_targets "$selected_kind" "$selected_path" "$selected_scheme" "$simulator" unit "${unit_targets[@]}")"
  fi

  if config_bool_enabled skip_ui_tests; then
    ui_status="skipped (config)"
  elif [[ "$policy" == "skip" && "$ui_detection" == "meaningful" ]]; then
    ui_status="skipped (policy)"
  elif [[ "$policy" == "prompt" && "$ui_detection" == "meaningful" ]]; then
    ui_status="prompt-required"
  else
    ui_status="$(status_for_targets "$selected_kind" "$selected_path" "$selected_scheme" "$simulator" ui "${ui_targets[@]}")"
  fi

  printf 'unit_tests=%s\n' "$unit_status"
  printf 'ui_tests=%s\n' "$ui_status"
  printf 'existing_tests_policy=%s\n' "$policy"
}

resolver_project_root() {
  printf '%s\n' "${BLITZ_PROJECT_ROOT:-$PWD}"
}

resolver_config_path() {
  if [[ -n "${BLITZ_CONFIG_PATH:-}" ]]; then
    printf '%s\n' "$BLITZ_CONFIG_PATH"
  else
    printf '%s/codex.blitz.toml\n' "$(resolver_project_root)"
  fi
}

resolver_config_value() {
  local key="$1"
  local file
  file="$(resolver_config_path)"

  [[ -f "$file" ]] || return 1

  awk -v key="$key" '
    $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
      sub(/^[^=]*=[[:space:]]*/, "", $0)
      sub(/[[:space:]]*#.*$/, "", $0)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      if ($0 ~ /^".*"$/) {
        sub(/^"/, "", $0)
        sub(/"$/, "", $0)
      }
      print $0
      exit
    }
  ' "$file"
}

allow_default_manual() {
  local value=""
  value="$(resolver_config_value allow_default_manual || true)"

  case "$value" in
    false|False|FALSE|0|no|NO)
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

resolve_configured_path() {
  local raw="$1"

  if [[ "$raw" = /* ]]; then
    printf '%s\n' "$raw"
  else
    printf '%s/%s\n' "$(resolver_project_root)" "$raw"
  fi
}

default_manual_path() {
  printf '%s/resources/default_ios_smoke_manual.yaml\n' "$SKILL_DIR"
}

manual_candidates() {
  local root
  root="$(resolver_project_root)"

  find \
    "$root/docs/testing" \
    "$root/docs/qa" \
    "$root/QA" \
    "$root/TestPlans" \
    "$root" \
    -maxdepth 3 \
    -type f \
    ! -path "$(default_manual_path)" \
    \( -iname '*manual*.md' -o -iname '*testplan*.md' -o -iname '*smoke*.yaml' -o -iname '*smoke*.yml' -o -iname '*regression*.md' -o -iname '*qa*.md' \) \
    2>/dev/null | sort -u
}

resolve_manual() {
  local configured_manual=""
  local candidates=()
  local candidate=""

  configured_manual="$(resolver_config_value manual_path || true)"
  if [[ -n "$configured_manual" ]]; then
    printf 'manual_source=config\nmanual_path=%s\n' "$(resolve_configured_path "$configured_manual")"
    return 0
  fi

  while IFS= read -r candidate; do
    [[ -n "$candidate" ]] && candidates+=("$candidate")
  done < <(manual_candidates)

  if [[ ${#candidates[@]} -eq 1 ]]; then
    printf 'manual_source=project\nmanual_path=%s\n' "${candidates[0]}"
    return 0
  fi

  if [[ ${#candidates[@]} -gt 1 ]]; then
    echo "Ambiguous test manual selection" >&2
    printf '%s\n' "${candidates[@]}" >&2
    return 1
  fi

  if allow_default_manual; then
    printf 'manual_source=default\nmanual_path=%s\n' "$(default_manual_path)"
    return 0
  fi

  echo "No test manual found and default manual is disabled" >&2
  return 1
}

runner_artifacts_dir() {
  if [[ -n "${BLITZ_ARTIFACTS_DIR:-}" ]]; then
    printf '%s\n' "$BLITZ_ARTIFACTS_DIR"
  else
    printf '%s/.blitz-artifacts/latest\n' "$PWD"
  fi
}

runner_derived_data_dir() {
  if [[ -n "${BLITZ_DERIVED_DATA_DIR:-}" ]]; then
    printf '%s\n' "$BLITZ_DERIVED_DATA_DIR"
  else
    printf '%s/.blitz-derived-data\n' "$PWD"
  fi
}

bundle_id_for_selection() {
  local kind="$1"
  local path="$2"
  local scheme="$3"
  local output=""

  if [[ -n "${BLITZ_BUNDLE_ID:-}" ]]; then
    printf '%s\n' "$BLITZ_BUNDLE_ID"
    return 0
  fi

  case "$kind" in
    workspace)
      output="$(PATH="$(lookup_path)" xcodebuild -showBuildSettings -scheme "$scheme" -workspace "$path" 2>/dev/null)"
      ;;
    project)
      output="$(PATH="$(lookup_path)" xcodebuild -showBuildSettings -scheme "$scheme" -project "$path" 2>/dev/null)"
      ;;
    *)
      echo "Unsupported project kind for bundle id discovery: $kind" >&2
      return 1
      ;;
  esac

  printf '%s\n' "$output" | awk -F' = ' '/PRODUCT_BUNDLE_IDENTIFIER/ { print $2; exit }'
}

build_app_for_selection() {
  local kind="$1"
  local path="$2"
  local scheme="$3"
  local simulator="$4"
  local derived_data=""

  if [[ -n "${BLITZ_APP_PATH:-}" ]]; then
    printf '%s\n' "$BLITZ_APP_PATH"
    return 0
  fi

  derived_data="$(runner_derived_data_dir)"
  mkdir -p "$derived_data"

  case "$kind" in
    workspace)
      PATH="$(lookup_path)" xcodebuild -workspace "$path" -scheme "$scheme" -destination "platform=iOS Simulator,name=$simulator" -derivedDataPath "$derived_data" build >/dev/null
      ;;
    project)
      PATH="$(lookup_path)" xcodebuild -project "$path" -scheme "$scheme" -destination "platform=iOS Simulator,name=$simulator" -derivedDataPath "$derived_data" build >/dev/null
      ;;
    *)
      echo "Unsupported project kind for build: $kind" >&2
      return 1
      ;;
  esac

  find "$derived_data/Build/Products" -type d -path '*Debug-iphonesimulator/*.app' | head -n 1
}

execute_blitz_flow() {
  local artifacts_dir="$1"
  local bundle_id="$2"

  mkdir -p "$artifacts_dir"
  PATH="$(lookup_path)" blitz launch "$bundle_id" >"$artifacts_dir/blitz-launch.log"
  PATH="$(lookup_path)" blitz snapshot >"$artifacts_dir/blitz-snapshot.txt"
  PATH="$(lookup_path)" blitz screenshot --output "$artifacts_dir/blitz-screen.png" >/dev/null
}

run_blitz_flow() {
  local selected_path=""
  local selected_kind=""
  local selected_scheme=""
  local simulator=""
  local bundle_id=""
  local app_path=""
  local artifacts_dir=""
  local manual_output=""

  selected_path="$(discover_candidate_path)"
  selected_kind="$(project_kind_for_path "$selected_path")"
  selected_scheme="$(discover_scheme_for_path "$selected_path")"
  simulator="$(runner_simulator_name)"
  bundle_id="$(bundle_id_for_selection "$selected_kind" "$selected_path" "$selected_scheme")"
  app_path="$(build_app_for_selection "$selected_kind" "$selected_path" "$selected_scheme" "$simulator")"
  artifacts_dir="$(runner_artifacts_dir)"
  manual_output="$(resolve_manual)"

  PATH="$(lookup_path)" xcrun simctl boot "$simulator" >/dev/null 2>&1 || true
  PATH="$(lookup_path)" xcrun simctl install booted "$app_path" >/dev/null

  execute_blitz_flow "$artifacts_dir" "$bundle_id"

  printf '%s\n' "$manual_output"
  printf 'simulator_name=%s\n' "$simulator"
  printf 'bundle_id=%s\n' "$bundle_id"
  printf 'app_path=%s\n' "$app_path"
  printf 'artifacts_dir=%s\n' "$artifacts_dir"
  printf 'blitz_status=passed\n'
}

report_value() {
  local key="$1"
  local text="$2"
  printf '%s\n' "$text" | sed -n "s/^$key=//p" | head -n 1
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

write_unified_report() {
  local output_dir="$1"
  local prepare_status="$2"
  local discover_output="$3"
  local test_output="$4"
  local blitz_output="$5"
  local blitz_status="$6"
  local report_json="$output_dir/report.json"
  local report_md="$output_dir/report.md"
  local final_verdict="failed"

  if [[ "$blitz_status" == "passed" ]]; then
    final_verdict="passed"
  fi

  mkdir -p "$output_dir"

  cat > "$report_json" <<EOF
{
  "environment_status": "$(json_escape "$prepare_status")",
  "project_path": "$(json_escape "$(report_value project_path "$discover_output")")",
  "project_kind": "$(json_escape "$(report_value project_kind "$discover_output")")",
  "scheme": "$(json_escape "$(report_value scheme "$discover_output")")",
  "xcode_mcp": "$(json_escape "$(report_value xcode_mcp "$discover_output")")",
  "unit_tests": "$(json_escape "$(report_value unit_tests "$test_output")")",
  "ui_tests": "$(json_escape "$(report_value ui_tests "$test_output")")",
  "manual_source": "$(json_escape "$(report_value manual_source "$blitz_output")")",
  "manual_path": "$(json_escape "$(report_value manual_path "$blitz_output")")",
  "simulator_name": "$(json_escape "$(report_value simulator_name "$blitz_output")")",
  "bundle_id": "$(json_escape "$(report_value bundle_id "$blitz_output")")",
  "app_path": "$(json_escape "$(report_value app_path "$blitz_output")")",
  "blitz_status": "$(json_escape "$blitz_status")",
  "final_verdict": "$(json_escape "$final_verdict")"
}
EOF

  cat > "$report_md" <<EOF
# Blitz App Smoke Report

- Environment: $prepare_status
- Project: $(report_value project_path "$discover_output")
- Kind: $(report_value project_kind "$discover_output")
- Scheme: $(report_value scheme "$discover_output")
- Xcode MCP: $(report_value xcode_mcp "$discover_output")
- Unit Tests: $(report_value unit_tests "$test_output")
- UI Tests: $(report_value ui_tests "$test_output")
- Manual Source: $(report_value manual_source "$blitz_output")
- Manual Path: $(report_value manual_path "$blitz_output")
- Simulator: $(report_value simulator_name "$blitz_output")
- Bundle ID: $(report_value bundle_id "$blitz_output")
- App Path: $(report_value app_path "$blitz_output")
- Blitz: $blitz_status
- Final Verdict: $final_verdict
EOF
}

blitz_command() {
  prepare_environment
  run_blitz_flow
}

report_command() {
  local report_file="$PWD/.blitz-artifacts/latest/report.md"
  if [[ ! -f "$report_file" ]]; then
    echo "No report found at $report_file" >&2
    return 1
  fi
  cat "$report_file"
}

run_command() {
  local prepare_status="passed"
  local discover_output=""
  local test_output=""
  local blitz_output=""
  local blitz_status="failed"
  local artifacts_dir=""
  local status=0

  prepare_environment
  discover_output="$(discover_command)"
  test_output="$(test_command)"

  if printf '%s\n' "$test_output" | grep -q 'prompt-required'; then
    cat >&2 <<'EOF'
Meaningful existing tests were detected.
Ask the user whether to run them or skip them, then either:
- set existing_tests_policy = "run" in codex.blitz.toml
- set existing_tests_policy = "skip" in codex.blitz.toml
- or use skip_unit_tests / skip_ui_tests for finer control
EOF
    return 2
  fi

  set +e
  blitz_output="$(run_blitz_flow 2>&1)"
  status=$?
  set -e
  if [[ $status -eq 0 ]]; then
    blitz_status="passed"
  fi

  artifacts_dir="$(report_value artifacts_dir "$blitz_output")"
  if [[ -z "$artifacts_dir" ]]; then
    artifacts_dir="$PWD/.blitz-artifacts/latest"
  fi

  write_unified_report "$artifacts_dir" "$prepare_status" "$discover_output" "$test_output" "$blitz_output" "$blitz_status"
  cat "$artifacts_dir/report.md"

  [[ "$blitz_status" == "passed" ]]
}

main() {
  local command="${1:-help}"

  case "$command" in
    help|-h|--help)
      show_usage
      ;;
    prepare)
      prepare_environment
      ;;
    discover)
      discover_command
      ;;
    test)
      test_command
      ;;
    blitz)
      blitz_command
      ;;
    report)
      report_command
      ;;
    run)
      run_command
      ;;
    *)
      echo "Unknown command: $command" >&2
      show_usage >&2
      return 1
      ;;
  esac
}

main "${@:-}"
