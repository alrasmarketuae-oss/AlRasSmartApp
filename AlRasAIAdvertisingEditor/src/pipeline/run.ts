import { VideoEditingService, type EditOptions } from "../services/VideoEditingService.js";

export async function runPipeline(options: EditOptions) {
  const service = new VideoEditingService();
  return service.edit(options);
}

export async function runRender(planPath: string, preview = false) {
  const service = new VideoEditingService();
  return service.renderPlan(planPath, preview);
}
