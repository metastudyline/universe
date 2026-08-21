use workshop0_sysmon::{SysReader, RingBuffer, SparklineRenderer};

fn main() {
    println!("✦ StudyLine Workshop 0: Sysmon 终端监控工具启动 ✦");
    let mem = SysReader::get_total_memory_mb();
    println!("检测到物理内存: {} MB", mem);

    let mut buf = RingBuffer::<10>::new();
    for i in 1..=10 {
        buf.push(i as f32 / 10.0);
    }

    let spark = SparklineRenderer::render(buf.as_slice());
    println!("CPU 负载波动波形图: [{}]", spark);
}
