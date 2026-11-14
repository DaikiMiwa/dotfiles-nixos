import { createSignal } from "solid-js";

export const [autoApproval, setAutoApproval] = createSignal<Record<string, boolean>>({});
let refreshing: Promise<void> | undefined;

export function autoApprovalMode(id: string): "ON" | "OFF" | "?" {
  const value = autoApproval()[id];
  return value === true ? "ON" : value === false ? "OFF" : "?";
}

export async function refreshAutoApproval(force = false): Promise<void> {
  if (refreshing) {
    await refreshing;
    if (!force) return;
  }
  refreshing = readAutoApproval();
  try {
    await refreshing;
  } finally {
    refreshing = undefined;
  }
}

async function readAutoApproval(): Promise<void> {
  try {
    const proc = Bun.spawn(["tmux-agent-autoapprove", "status", "--json"], {
      stdout: "pipe", stderr: "pipe",
    });
    const [output, code] = await Promise.all([new Response(proc.stdout).text(), proc.exited]);
    if (code !== 0) throw new Error("Cannot read auto approval state");
    setAutoApproval(JSON.parse(output));
  } catch {
    // Unknown state must never be advertised as enabled.
    setAutoApproval({});
  }
}

export async function toggleAutoApproval(id: string): Promise<void> {
  const proc = Bun.spawn(["tmux-agent-autoapprove", "toggle", id], {
    stdout: "pipe", stderr: "pipe",
  });
  const [error, code] = await Promise.all([new Response(proc.stderr).text(), proc.exited]);
  if (code !== 0) throw new Error(error.trim() || "Cannot change auto approval");
  await refreshAutoApproval(true);
}
