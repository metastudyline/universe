use workshop0_sysmon::{SysReader, RingBuffer, SparklineRenderer};

#[test]
fn test_step1_reader() {
    let mem = SysReader::get_total_memory_mb();
    assert!(mem > 0, "Total memory should be positive");
    let load = SysReader::get_sample_load();
    assert!(load >= 0.0 && load <= 1.0, "CPU load must be in [0, 1]");
}

#[test]
fn test_step2_buffer() {
    let mut buf = RingBuffer::<5>::new();
    assert_eq!(buf.len(), 0);
    assert!(buf.is_empty());

    buf.push(0.1);
    buf.push(0.2);
    assert_eq!(buf.len(), 2);

    for _ in 0..10 {
        buf.push(0.5);
    }
    assert_eq!(buf.len(), 5, "RingBuffer must not exceed capacity");
}

#[test]
fn test_step3_render() {
    let vals = [0.0, 0.5, 1.0];
    let spark = SparklineRenderer::render(&vals);
    assert_eq!(spark.chars().count(), 3);
}
