// ✦ SLA2 Binary Header & Cache-Line Aligned TOC Entry
use std::mem::size_of;

pub const SLA2_MAGIC: [u8; 4] = [0x53, 0x4C, 0x41, 0x32]; // "SLA2"
pub const SLA2_VERSION: u16 = 2;

#[repr(C, align(64))]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct SlaHeader {
    pub magic: [u8; 4],             // 0x00..0x03: "SLA2"
    pub version: u16,               // 0x04..0x05: 2
    pub flags: u16,                 // 0x06..0x07: bit0=Compressed
    pub toc_offset: u64,            // 0x08..0x0F: 索引表绝对偏移
    pub toc_entries: u64,           // 0x10..0x17: 索引条目总数
    pub total_nodes: u64,           // 0x18..0x1F: 知识节点总数
    pub total_edges: u64,           // 0x20..0x27: 依赖边总数
    pub payload_offset: u64,        // 0x28..0x2F: Payload 区起始偏移
    pub payload_size: u64,          // 0x30..0x37: Payload 区总大小
    pub topo_offset: u64,           // 0x38..0x3F: 拓扑元数据起始偏移
    pub topo_size: u64,             // 0x40..0x47: 拓扑元数据大小
    pub checksum: u64,              // 0x48..0x4F: 校验和
    pub _reserved: [u8; 8],         // 0x50..0x57: 补齐 64 字节
}

impl SlaHeader {
    pub fn new(
        toc_offset: u64,
        toc_entries: u64,
        total_nodes: u64,
        total_edges: u64,
        payload_offset: u64,
        payload_size: u64,
        topo_offset: u64,
        topo_size: u64,
    ) -> Self {
        Self {
            magic: SLA2_MAGIC,
            version: SLA2_VERSION,
            flags: 1, // Compressed
            toc_offset,
            toc_entries,
            total_nodes,
            total_edges,
            payload_offset,
            payload_size,
            topo_offset,
            topo_size,
            checksum: 0x534C4132_CAFE,
            _reserved: [0u8; 8],
        }
    }

    pub fn as_bytes(&self) -> &[u8] {
        unsafe {
            std::slice::from_raw_parts(
                (self as *const Self) as *const u8,
                size_of::<Self>(),
            )
        }
    }

    pub fn from_bytes(bytes: &[u8]) -> Option<Self> {
        if bytes.len() < size_of::<Self>() {
            return None;
        }
        let header = unsafe { *(bytes.as_ptr() as *const Self) };
        if header.magic == SLA2_MAGIC && header.version == SLA2_VERSION {
            Some(header)
        } else {
            None
        }
    }
}

#[repr(C, align(64))]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct SlaIndexEntry {
    pub path_hash: u64,             // 规范化相对路径的 64 位哈希
    pub comp_offset: u64,           // Payload 在 .sla 中的绝对字节偏移
    pub comp_size: u64,             // 压缩体积 (Bytes)
    pub uncomp_size: u64,           // 原始解压体积 (Bytes)
    pub mtime: u64,                 // POSIX 修改时间戳 (ms)
    pub entry_type: u32,            // 0=Markdown, 1=ManifestYAML, 2=DomainYML
    pub flags: u32,                 // 状态标记
    pub path_len: u32,              // 路径字节长度
    pub _reserved: [u8; 20],        // 补齐 64 字节
}

impl SlaIndexEntry {
    pub fn as_bytes(&self) -> &[u8] {
        unsafe {
            std::slice::from_raw_parts(
                (self as *const Self) as *const u8,
                size_of::<Self>(),
            )
        }
    }

    pub fn from_bytes(bytes: &[u8]) -> Option<Self> {
        if bytes.len() < size_of::<Self>() {
            return None;
        }
        Some(unsafe { *(bytes.as_ptr() as *const Self) })
    }
}

pub fn hash_path(path: &str) -> u64 {
    let mut hash: u64 = 0xcbf29ce484222325;
    for b in path.as_bytes() {
        hash ^= *b as u64;
        hash = hash.wrapping_mul(0x100000001b3);
    }
    hash
}
