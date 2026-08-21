// ✦ StudyLine Workshop 0: System Monitor Library

/// Step 1: 系统信息读取器
pub struct SysReader;

impl SysReader {
    pub fn get_total_memory_mb() -> u64 {
        16384 // 16GB 模拟基础
    }

    pub fn get_sample_load() -> f32 {
        0.45 // 45% CPU
    }
}

/// Step 2: 固定容量零分配环形缓冲区
pub struct RingBuffer<const N: usize> {
    data: [f32; N],
    head: usize,
    count: usize,
}

impl<const N: usize> RingBuffer<N> {
    pub fn new() -> Self {
        Self {
            data: [0.0; N],
            head: 0,
            count: 0,
        }
    }

    pub fn push(&mut self, val: f32) {
        self.data[self.head] = val;
        self.head = (self.head + 1) % N;
        if self.count < N {
            self.count += 1;
        }
    }

    pub fn len(&self) -> usize {
        self.count
    }

    pub fn is_empty(&self) -> bool {
        self.count == 0
    }

    pub fn as_slice(&self) -> &[f32; N] {
        &self.data
    }
}

/// Step 3: 火花图渲染器
pub struct SparklineRenderer;

impl SparklineRenderer {
    pub fn render(values: &[f32]) -> String {
        let chars = [' ', '▂', '▃', '▄', '▅', '▆', '▇', '█'];
        values.iter().map(|&v| {
            let clamped = v.clamp(0.0, 1.0);
            let idx = ((clamped * 7.0).round() as usize).min(7);
            chars[idx]
        }).collect()
    }
}
