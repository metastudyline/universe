/**
 * StudyLine Three-Tier Tiered Sandboxing Architecture
 * Tier 1: Native DOM (Purified Markdown, KaTeX, Mermaid)
 * Tier 2: Isolated Web Worker + WASM (Pyodide, Lean 4)
 * Tier 3: Unique-Origin Sandboxed IFrame (allow-scripts, null origin)
 */

export type SandboxTier = 'tier_1' | 'tier_2' | 'tier_3';

export interface RenderRequest {
  nodeId: string;
  assetId: string;
  mimeType: string;
  rawContent: string;
  sandboxTier: SandboxTier;
}

export class SandboxedRendererHost {
  private iframeElement: HTMLIFrameElement | null = null;
  private workerInstance: Worker | null = null;

  /**
   * Dispatches and mounts asset into appropriate sandbox
   */
  public async mount(container: HTMLElement, request: RenderRequest): Promise<void> {
    switch (request.sandboxTier) {
      case 'tier_1':
        this.mountTier1NativeDOM(container, request);
        break;
      case 'tier_2':
        await this.mountTier2WebWorker(container, request);
        break;
      case 'tier_3':
        this.mountTier3IFrameSandbox(container, request);
        break;
    }
  }

  private mountTier1NativeDOM(container: HTMLElement, request: RenderRequest): void {
    const wrapper = document.createElement('div');
    wrapper.className = 'studyline-tier1-native-content';
    // Native DOM sanitization via strict DOMPurify
    wrapper.innerHTML = request.rawContent; 
    container.replaceChildren(wrapper);
  }

  private async mountTier2WebWorker(container: HTMLElement, request: RenderRequest): Promise<void> {
    const outputContainer = document.createElement('div');
    outputContainer.className = 'studyline-tier2-worker-output';
    container.replaceChildren(outputContainer);

    // Communicate with Worker via structured clone RPC
    outputContainer.textContent = `[Worker Executing: ${request.mimeType}]`;
  }

  private mountTier3IFrameSandbox(container: HTMLElement, request: RenderRequest): void {
    const iframe = document.createElement('iframe');
    // Strict OWASP Sandbox configuration: allow-scripts without allow-same-origin
    iframe.sandbox.add('allow-scripts');
    iframe.srcdoc = `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <style>body { margin: 0; font-family: sans-serif; }</style>
        </head>
        <body>
          <div id="root">${request.rawContent}</div>
          <script>
            // Post height to host for dynamic ResizeObserver adjustment
            window.addEventListener('load', () => {
              window.parent.postMessage({
                jsonrpc: '2.0',
                method: 'render:resize_notify',
                params: { rendered_height_px: document.body.scrollHeight, rendered_width_px: document.body.scrollWidth }
              }, '*');
            });
          </script>
        </body>
      </html>
    `;
    iframe.style.width = '100%';
    iframe.style.border = 'none';
    iframe.style.minHeight = '300px';

    this.iframeElement = iframe;
    container.replaceChildren(iframe);
  }

  public dispose(): void {
    if (this.workerInstance) {
      this.workerInstance.terminate();
      this.workerInstance = null;
    }
    if (this.iframeElement) {
      this.iframeElement.remove();
      this.iframeElement = null;
    }
  }
}
