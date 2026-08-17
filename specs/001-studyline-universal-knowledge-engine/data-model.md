# Data Model: StudyLine Universal Knowledge & Research Open Infrastructure

**Feature Identifier**: `001-studyline-universal-knowledge-engine`  
**Status**: Revised (Federated Hub-and-Spoke Entities Added)  
**Created**: 2026-08-17  

---

## 1. 实体关系全景 (Entity-Relationship Overview)

```mermaid
erDiagram
    KnowledgeHubRegistry ||--o{ FederatedDomainRepository : "tracks & indexes"
    FederatedDomainRepository ||--o{ KnowledgeNode : "exports namespace"
    KnowledgeNode ||--o{ DependencyEdge : "declares prerequisites"
    KnowledgeNode ||--o{ MultimodalAsset : "bundles"
    KnowledgeNode ||--o{ PedagogicalBreakageIssue : "tracked by"
    KnowledgePullRequest ||--o{ KnowledgeNode : "modifies"
    KnowledgePullRequest ||--|| BlastRadiusReport : "generates"

    KnowledgeHubRegistry {
        string registry_version "版本号 (e.g. 1.0.0)"
        datetime last_updated "最后全局编译时间"
        int total_nodes_count "全网总知识节点数"
        int total_repositories_count "全网子仓库总数"
    }

    FederatedDomainRepository {
        string namespace PK "唯一命名空间前缀"
        string repository_url "Git 公开克隆 URL"
        string target_branch "主跟踪分支"
        string pinned_release_tag "最新稳定 Release Tag"
        string pinned_commit_sha "40位 Git Commit SHA"
        string domain_category "所属主领域"
        string[] maintainer_team "维护团队 GitHub Handles"
        string exported_node_prefix "该仓库管辖的节点 URI 前缀"
        int node_count "节点总数"
        string status "状态 (active | deprecated | quarantined)"
    }

    KnowledgeNode {
        string id PK "URI 格式全局唯一标识"
        string title "节点标题"
        string domain "所属学科领域"
        string summary "核心学术摘要"
        string schema_version "元规范版本 (e.g. 1.0.0)"
        string content_hash "当前提交内容 SHA-256 校验和"
        string license "知识开源协议 (e.g. CC-BY-SA-4.0)"
        string[] maintainers "领域 Maintainer GitHub ID 列表"
        datetime created_at "创建时间 ISO-8601"
        datetime updated_at "更新时间 ISO-8601"
    }

    DependencyEdge {
        string target_node_id PK "前置目标节点 ID (支持跨子仓 URI)"
        string dependency_type "依赖性质 (strict | supporting)"
        int min_mastery_level "前置最低掌握等级 (0..5)"
        string rationale "教学/逻辑依赖理由说明"
    }

    MultimodalAsset {
        string asset_id PK "资产唯一路径或哈希"
        string node_id FK "所属节点 ID"
        string role "资产角色 (lecture | proof | widget | dataset | raw_archive)"
        string mime_type "标准 MIME 类型"
        string relative_path "相对于节点根目录路径"
        string checksum "资产文件 SHA-256"
        int file_size_bytes "文件体积 (字节)"
    }

    KnowledgePullRequest {
        string pr_id PK "PR 编号"
        string author "贡献者 GitHub 句柄"
        string pr_status "PR 状态 (open | merged | closed)"
        string ci_status "CI 总体状态 (pending | passed | failed)"
        string[] direct_changed_nodes "直接修改的节点列表"
        string[] affected_downstream_nodes "传递闭包波及节点列表"
    }
```

---

## 2. 实体规格与字段定义 (Entity Specifications)

### 2.1 `KnowledgeHubRegistry` (母仓库注册表)
- **描述**：母仓库 `universe` 中维护的全局联邦注册表实体，对应 `registry.yml`。
- **字段定义**：
  | 字段名 | 类型 | 必填 | 约束 / 枚举 / 格式 | 说明 |
  | :--- | :--- | :---: | :--- | :--- |
  | `registry_version` | `string` | 是 | SemVer (e.g. `1.0.0`) | 注册表格式版本 |
  | `last_updated` | `string` | 是 | Format: `date-time` (ISO-8601) | 全局大图最后编译生成时间 |
  | `domain_repositories` | `FederatedDomainRepository[]` | 是 | MinItems: 1 | 全网登记的子仓库清单 |

---

### 2.2 `FederatedDomainRepository` (联邦学科子仓库)
- **描述**：各个独立学科团队或机构维护的子仓库描述。
- **字段定义**：
  | 字段名 | 类型 | 必填 | 约束 / 枚举 / 格式 | 说明 |
  | :--- | :--- | :---: | :--- | :--- |
  | `namespace` | `string` | 是 | Pattern: `^[a-z0-9-]+$` (e.g. `philosophy`, `cs-systems`) | 唯一短命名空间 |
  | `repository_url` | `string` | 是 | Format: `uri` (e.g. `https://github.com/studyline/domain-philosophy.git`) | Git Clone 访问地址 |
  | `target_branch` | `string` | 是 | e.g. `main` | 默认跟踪分支 |
  | `pinned_release_tag` | `string` | 是 | e.g. `v1.2.0` | 锁定的最新稳定 Release 标签 |
  | `pinned_commit_sha` | `string` | 是 | 长度: 40, Hex SHA-1 | 对应的 Git Commit 哈希 |
  | `domain_category` | `string` | 是 | 枚举: `philosophy`, `mathematics`, `computer_science`, `natural_science`, `life_hacker`, `social_science` | 所属主学科大类 |
  | `maintainer_team` | `string[]` | 是 | MinItems: 1 | 负责维护该子仓的 GitHub 团队或专家句柄 |
  | `exported_node_prefix` | `string` | 是 | Pattern: `^[a-z0-9-]+(\.[a-z0-9-]+)*$` | 该仓库管辖的节点 URI 前缀 |
  | `node_count` | `integer` | 是 | $\ge 1$ | 经 CI 验证包含的有效知识节点数 |
  | `status` | `string` | 是 | 枚举: `active`, `deprecated`, `quarantined` | 联邦健康状态 |

---

### 2.3 `KnowledgeNode` (知识节点)
- **描述**：人类知识大仓库的基本原子单元，对应子仓库中的一个开放多模态容器目录。
- **字段定义**：
  | 字段名 | 类型 | 必填 | 约束 / 枚举 / 格式 | 说明 |
  | :--- | :--- | :---: | :--- | :--- |
  | `id` | `string` | 是 | Pattern: `^[a-z0-9-]+(\.[a-z0-9-]+)*$` | 全局唯一语义标识符 |
  | `title` | `string` | 是 | 长度: 2..120 字符 | 节点显示名称 |
  | `domain` | `string` | 是 | 枚举: 6大学科大类 | 一级学科归属 |
  | `summary` | `string` | 是 | 长度: 10..500 字符 | 简短学术/教学摘要 |
  | `schema_version` | `string` | 是 | SemVer (e.g. `1.0.0`) | 元契约版本 |
  | `content_hash` | `string` | 是 | 长度: 64, Hex SHA-256 | 节点资产综合内容哈希 |
  | `license` | `string` | 是 | e.g. `CC-BY-SA-4.0` | 知识开源协议 |
  | `maintainers` | `string[]` | 是 | MinItems: 1 | 负责该节点的维护者句柄 |
  | `prerequisites` | `DependencyEdge[]` | 是 | 数组 (允许为空作为根节点) | 前置依赖关系集合 |
  | `assets` | `MultimodalAsset[]` | 是 | 数组 (至少包含 1 个入口资产) | 挂载的多模态资产清单 |
  | `created_at` | `string` | 是 | Format: `date-time` | 创建时间 |
  | `updated_at` | `string` | 是 | Format: `date-time` | 更新时间 |

---

### 2.4 `DependencyEdge` (依赖关系边)
- **描述**：知识拓扑 DAG 中的有向边，支持同仓库内依赖与跨子仓前置依赖。
- **字段定义**：
  | 字段名 | 类型 | 必填 | 约束 / 枚举 / 格式 | 说明 |
  | :--- | :--- | :---: | :--- | :--- |
  | `target_node_id` | `string` | 是 | 必须在全局母仓索引中真实存在 | 前置依赖节点全局 ID |
  | `dependency_type` | `string` | 是 | 枚举: `strict` (硬性前置), `supporting` (辅助推荐) | 依赖强度 |
  | `min_mastery_level` | `integer` | 是 | 范围: `0` 到 `5` | 下游学习所需的最低掌握层次 |
  | `rationale` | `string` | 否 | 长度: 5..300 字符 | 设立前置关系的认知依据 |
