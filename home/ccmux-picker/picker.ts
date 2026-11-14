// Native ccmux UI, connected to the existing Homebrew daemon. Deliberately
// avoid CLI daemon reconciliation: this extension is a UI client, not a server.
import { launchTUI } from "./tui";
import { getPreferences } from "./lib/preferences";
import { getUIState, resolvePromptDisplay } from "./lib/state";
import { setPinnedTmuxClientTty } from "./lib/tmux-client";
import { forkableAgentNames } from "./lib/agents";

if (process.env.CCMUX_CALLER_PWD) process.chdir(process.env.CCMUX_CALLER_PWD);
const args = process.argv.slice(2);
const client = args.indexOf("--client-tty");
if (client >= 0) setPinnedTmuxClientTty(args[client + 1]);
const [prefs, ui] = await Promise.all([getPreferences(), getUIState()]);
await launchTUI({
  initialPreview: true,
  iconStyle: prefs.iconStyle ?? "dot",
  previewWidth: ui.previewWidth ?? prefs.previewWidth,
  columns: prefs.columns,
  promptLines: prefs.promptLines,
  breakpoints: prefs.breakpoints,
  ageFadeAfter: prefs.ageFade?.after,
  attentionBand: prefs.attentionBand,
  searchPaneContent: prefs.searchPaneContent,
  searchPaneLines: prefs.searchPaneLines,
  searchTranscript: prefs.searchTranscript,
  groupBy: ui.groupBy ?? prefs.groupBy,
  collapsedGroups: ui.collapsedGroups,
  pinnedGroups: ui.pinnedGroups,
  hideIdle: ui.hideIdle,
  promptDisplay: resolvePromptDisplay(ui, prefs.promptDisplay),
  persistent: false,
  lastSpawnAgent: ui.lastSpawnAgent,
  reviewHandback: prefs.reviewHandback,
  forkableAgents: forkableAgentNames(prefs),
  theme: prefs.theme,
});
