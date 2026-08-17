/**
 * StudyLine WebVTT Bidirectional Audio-Text Synchronization Engine
 * Forward Sync: Video currentTime cuechange -> Smooth scroll & highlight text
 * Backward Sync: User clicks timestamp in text -> videoElement.currentTime = t
 */

export interface TimeCue {
  id: string;
  startTime: number;
  endTime: number;
  textAnchorId: string;
}

export class MediaSyncEngine {
  private videoElement: HTMLVideoElement | null = null;
  private cues: TimeCue[] = [];
  private activeCueId: string | null = null;

  constructor(cues: TimeCue[]) {
    this.cues = cues;
  }

  public bindVideo(video: HTMLVideoElement): void {
    this.videoElement = video;
    this.videoElement.addEventListener('timeupdate', this.onTimeUpdate);
  }

  private onTimeUpdate = (): void => {
    if (!this.videoElement) return;
    const currentTime = this.videoElement.currentTime;

    // Binary search / find active cue
    const currentCue = this.cues.find(
      (cue) => currentTime >= cue.startTime && currentTime <= cue.endTime
    );

    if (currentCue && currentCue.id !== this.activeCueId) {
      this.activeCueId = currentCue.id;
      this.highlightAndScrollToAnchor(currentCue.textAnchorId);
    }
  };

  /**
   * Backward Sync: Click on text paragraph jumps video to timestamp
   */
  public seekToTimestamp(timestampSeconds: number): void {
    if (this.videoElement) {
      this.videoElement.currentTime = timestampSeconds;
      if (this.videoElement.paused) {
        this.videoElement.play().catch(() => {});
      }
    }
  }

  private highlightAndScrollToAnchor(anchorId: string): void {
    const targetElement = document.getElementById(anchorId);
    if (targetElement) {
      // Remove previous active highlights
      document.querySelectorAll('.studyline-active-cue').forEach((el) => {
        el.classList.remove('studyline-active-cue');
      });

      targetElement.classList.add('studyline-active-cue');
      targetElement.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
  }

  public unbind(): void {
    if (this.videoElement) {
      this.videoElement.removeEventListener('timeupdate', this.onTimeUpdate);
      this.videoElement = null;
    }
  }
}
