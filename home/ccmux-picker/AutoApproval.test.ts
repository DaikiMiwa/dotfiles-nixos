import { afterEach, expect, mock, spyOn, test } from "bun:test";
import { autoApprovalMode, refreshAutoApproval, toggleAutoApproval } from "./AutoApproval";

afterEach(() => mock.restore());

function processResult(output: string, code = 0) {
  return { stdout: new Response(output).body, stderr: new Response(code ? output : "").body,
    exited: Promise.resolve(code) } as ReturnType<typeof Bun.spawn>;
}

test("reads per-session state and distinguishes unavailable state", async () => {
  const spawn = spyOn(Bun, "spawn").mockImplementation(() => processResult('{"one":true,"two":false}'));
  await refreshAutoApproval();
  expect(autoApprovalMode("one")).toBe("ON");
  expect(autoApprovalMode("two")).toBe("OFF");
  expect(autoApprovalMode("missing")).toBe("?");
  spawn.mockImplementation(() => processResult("unavailable", 1));
  await refreshAutoApproval();
  expect(autoApprovalMode("one")).toBe("?");
});

test("toggles exactly the selected agent, then refreshes its badge", async () => {
  const spawn = spyOn(Bun, "spawn").mockImplementation((argv) =>
    processResult(argv[1] === "toggle" ? "" : '{"selected":true,"other":false}'));
  await toggleAutoApproval("selected");
  expect(spawn.mock.calls[0][0]).toEqual(["tmux-agent-autoapprove", "toggle", "selected"]);
  expect(autoApprovalMode("selected")).toBe("ON");
  expect(autoApprovalMode("other")).toBe("OFF");
});

test("a failed toggle is reported rather than displayed as success", async () => {
  spyOn(Bun, "spawn").mockImplementation(() => processResult("session was replaced", 1));
  await expect(toggleAutoApproval("gone")).rejects.toThrow("session was replaced");
});
