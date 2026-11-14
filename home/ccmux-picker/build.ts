import solidPlugin from "@opentui/solid/bun-plugin";
import core from "@opentui/core/package.json";

const result = await Bun.build({
  entrypoints: ["src/dotfiles-picker.ts"],
  target: "bun",
  outdir: "picker-dist",
  plugins: [solidPlugin],
  external: ["x11", ...Object.keys(core.optionalDependencies ?? {})],
});
if (!result.success) {
  for (const log of result.logs) console.error(log);
  process.exit(1);
}
