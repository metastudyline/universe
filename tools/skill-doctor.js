#!/usr/bin/env node

/**
 * Antigravity Skill Doctor & Health Governance Engine
 * Strictly adheres to contracts/skill-doctor-contract.json
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

const HOME = os.homedir();
const GLOBAL_SKILLS_DIR = path.join(HOME, '.agents', 'skills');
const GLOBAL_CONFIG_DIR = path.join(HOME, '.gemini', 'config');
const GLOBAL_CONFIG_FILE = path.join(GLOBAL_CONFIG_DIR, 'config.json');
const GLOBAL_SKILLS_FILE = path.join(GLOBAL_CONFIG_DIR, 'skills.json');
const PLUGINS_DIR = path.join(GLOBAL_CONFIG_DIR, 'plugins');
const BUILTIN_DIR = path.join(HOME, '.gemini', 'antigravity', 'builtin', 'skills');
const WORKSPACE_ROOT = process.cwd();
const WORKSPACE_SKILLS_DIR = path.join(WORKSPACE_ROOT, '.agents', 'skills');
const WORKSPACE_SKILLS_FILE = path.join(WORKSPACE_ROOT, '.agents', 'skills.json');

function parseFrontmatter(filePath) {
  try {
    if (!fs.existsSync(filePath)) return null;
    const content = fs.readFileSync(filePath, 'utf8');
    const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
    if (!match) return null;
    const yaml = match[1];
    
    let name = '';
    let description = '';
    
    const nameMatch = yaml.match(/^name:\s*["']?([^"'\r\n]+)["']?/m);
    if (nameMatch) name = nameMatch[1].trim();
    
    const descMatch = yaml.match(/^description:\s*(?:>-\s*|\|-\s*|["'])?([\s\S]*?)(?=\n[a-zA-Z0-9_-]+:\s*|$)/m);
    if (descMatch) {
      description = descMatch[1]
        .split(/\r?\n/)
        .map(line => line.trim())
        .filter(line => line.length > 0)
        .join(' ')
        .replace(/^["']|["']$/g, '')
        .trim();
    }
    
    return { name, description, content };
  } catch (e) {
    return null;
  }
}

function estimateTokens(text) {
  if (!text) return 0;
  // Standard heuristic: ~4 chars per token + formatting overhead
  return Math.ceil(text.length / 3.8);
}

function scanDirectoryForSkills(baseDir, source, tierDefault) {
  const skills = [];
  if (!fs.existsSync(baseDir)) return skills;
  
  const entries = fs.readdirSync(baseDir, { withFileTypes: true });
  for (const entry of entries) {
    if (entry.isDirectory()) {
      const skillDir = path.join(baseDir, entry.name);
      const skillFile = path.join(skillDir, 'SKILL.md');
      if (fs.existsSync(skillFile)) {
        const fm = parseFrontmatter(skillFile);
        const hasReferences = fs.existsSync(path.join(skillDir, 'references'));
        const hasScripts = fs.existsSync(path.join(skillDir, 'scripts'));
        
        let tier = tierDefault;
        if (entry.name.startsWith('speckit-')) {
          tier = 'L1_SPECKIT_PIPELINE';
        } else if (['code-review', 'git-workflow', 'design-patterns-guide', 'documentation', 'api-design', 'performance-optimization', 'stuck'].includes(entry.name)) {
          tier = 'L0_CORE_ENGINEERING';
        } else if (['impeccable-ui-kit', 'theme-wsj-editorial', 'ttzip-ui-design-system'].includes(entry.name)) {
          tier = 'L2_DOMAIN_BUNDLE';
        }

        const skillId = entry.name.toLowerCase();
        const skillName = fm ? (fm.name || skillId) : skillId;
        const skillDesc = fm ? (fm.description || 'No description provided.') : 'No description provided.';
        const tokenEst = estimateTokens(skillName + ' ' + skillDesc);

        skills.push({
          skill_id: skillId,
          name: skillName,
          description: skillDesc,
          directory_path: skillDir,
          skill_file_path: skillFile,
          tier: tier,
          source: source,
          status: fm ? 'ENABLED' : 'INVALID_FRONTMATTER',
          estimated_token_count: tokenEst,
          has_references: hasReferences,
          has_scripts: hasScripts
        });
      }
    }
  }
  return skills;
}

function runAudit() {
  const issues = [];
  const recommendations = [];
  
  // 1. Read config.json
  let configJson = { plugins: {} };
  if (fs.existsSync(GLOBAL_CONFIG_FILE)) {
    try {
      configJson = JSON.parse(fs.readFileSync(GLOBAL_CONFIG_FILE, 'utf8'));
    } catch (e) {
      issues.push({
        issue_code: 'UNRESOLVED_PATH',
        severity: 'ERROR',
        target_id: GLOBAL_CONFIG_FILE,
        message: 'Failed to parse global config.json: ' + e.message
      });
    }
  }

  // 2. Scan Plugins
  const plugins = [];
  if (fs.existsSync(PLUGINS_DIR)) {
    const pEntries = fs.readdirSync(PLUGINS_DIR, { withFileTypes: true });
    for (const pEntry of pEntries) {
      if (pEntry.isDirectory()) {
        const pDir = path.join(PLUGINS_DIR, pEntry.name);
        const pManifest = path.join(pDir, 'plugin.json');
        let displayName = pEntry.name;
        let isDefaultDisabled = false;
        
        if (fs.existsSync(pManifest)) {
          try {
            const m = JSON.parse(fs.readFileSync(pManifest, 'utf8'));
            displayName = m.name || displayName;
            isDefaultDisabled = !!m.disabled;
          } catch (e) {}
        }
        
        const isConfigEnabled = configJson.plugins && configJson.plugins[pEntry.name] 
          ? configJson.plugins[pEntry.name].enabled !== false
          : !isDefaultDisabled;

        const pSkills = scanDirectoryForSkills(path.join(pDir, 'skills'), 'GLOBAL_DISCOVERY', 'L2_DOMAIN_BUNDLE');
        
        plugins.push({
          plugin_id: pEntry.name,
          display_name: displayName,
          directory_path: pDir,
          is_enabled_in_config: isConfigEnabled,
          is_disabled_in_manifest: isDefaultDisabled,
          skill_count: pSkills.length,
          skill_ids: pSkills.map(s => s.skill_id)
        });
      }
    }
  }

  // 3. Scan Skills Across Tiers
  const globalSkills = scanDirectoryForSkills(GLOBAL_SKILLS_DIR, 'GLOBAL_DECLARED', 'L0_CORE_ENGINEERING');
  const builtinSkills = scanDirectoryForSkills(BUILTIN_DIR, 'BUILTIN', 'L0_CORE_ENGINEERING');
  const workspaceSkills = scanDirectoryForSkills(WORKSPACE_SKILLS_DIR, 'WORKSPACE_PROJECT', 'L2_DOMAIN_BUNDLE');

  // Collect all skills
  const allSkills = [...globalSkills, ...builtinSkills, ...workspaceSkills];
  
  // Add plugin skills with their enabled/disabled state
  for (const plugin of plugins) {
    const pSkills = scanDirectoryForSkills(path.join(plugin.directory_path, 'skills'), 'GLOBAL_DISCOVERY', 'L2_DOMAIN_BUNDLE');
    for (const ps of pSkills) {
      if (!plugin.is_enabled_in_config) {
        ps.status = 'DISABLED';
      }
      allSkills.push(ps);
    }
  }

  // Check name collisions
  const seenNames = new Map();
  for (const s of allSkills) {
    if (seenNames.has(s.skill_id)) {
      issues.push({
        issue_code: 'DUPLICATE_NAME_COLLISION',
        severity: 'WARNING',
        target_id: s.skill_id,
        message: `Skill ID collision between ${seenNames.get(s.skill_id)} and ${s.directory_path}`
      });
    } else {
      seenNames.set(s.skill_id, s.directory_path);
    }
  }

  // Budget calculations
  const activeSkills = allSkills.filter(s => s.status === 'ENABLED');
  const disabledSkills = allSkills.filter(s => s.status === 'DISABLED');
  
  // Safe budget threshold in Antigravity is around 65 active skills in system prompt
  const SAFE_PROMPT_SKILL_LIMIT = 60;
  const excludedCount = activeSkills.length > SAFE_PROMPT_SKILL_LIMIT ? (activeSkills.length - SAFE_PROMPT_SKILL_LIMIT) : 0;
  const isHealthy = excludedCount === 0;

  if (!isHealthy) {
    issues.push({
      issue_code: 'OVER_BUDGET_DROP',
      severity: 'ERROR',
      target_id: 'SYSTEM_PROMPT_SKILLS_BUDGET',
      message: `Active skills (${activeSkills.length}) exceeds safe limit (${SAFE_PROMPT_SKILL_LIMIT}). Approximately ${excludedCount} skills risk truncation.`
    });
    recommendations.push('Disable heavy unused plugins in ~/.gemini/config/config.json (e.g. science, data-agent-kit-plugin).');
    recommendations.push('Aggregate atomic micro-skills into Hub Skills (like impeccable-ui-kit).');
  }

  const estimatedTotalTokens = activeSkills.reduce((sum, s) => sum + s.estimated_token_count, 0);

  const report = {
    report_version: "1.0.0",
    scan_timestamp: new Date().toISOString(),
    total_discovered_skills: allSkills.length,
    active_skills_count: activeSkills.length,
    disabled_skills_count: disabledSkills.length,
    excluded_skills_count: excludedCount,
    estimated_total_prompt_tokens: estimatedTotalTokens,
    is_budget_healthy: isHealthy,
    skills: allSkills,
    plugins: plugins,
    issues: issues,
    recommendations: recommendations
  };

  return report;
}

// CLI entry point
const args = process.argv.slice(2);
const isJson = args.includes('--json');
const isCheck = args.includes('--check');

const report = runAudit();

if (isJson) {
  console.log(JSON.stringify(report, null, 2));
} else {
  console.log('\n============================================================');
  console.log('       ANTIGRAVITY SKILL DOCTOR & HEALTH AUDITOR            ');
  console.log('============================================================');
  console.log(`[✓] Discovered Total Skills: ${report.total_discovered_skills}`);
  console.log(`[✓] Active Ingested Skills:  ${report.active_skills_count} (Healthy <= 60)`);
  console.log(`[✓] Disabled Plugin Skills:  ${report.disabled_skills_count}`);
  console.log(`[✓] Estimated Prompt Tokens: ~${report.estimated_total_prompt_tokens} Tokens`);
  
  if (report.is_budget_healthy) {
    console.log(`[✓] Context Budget Status:   HEALTHY (0 Over-budget Drops)`);
  } else {
    console.log(`[✗] Context Budget Status:   WARNING (${report.excluded_skills_count} Skills Dropped)`);
  }
  
  console.log('------------------------------------------------------------');
  console.log(' PLUGINS STATUS:');
  for (const p of report.plugins) {
    const statusMark = p.is_enabled_in_config ? '[✓ ENABLED ]' : '[○ DISABLED]';
    console.log(`  ${statusMark} ${p.plugin_id.padEnd(28)} (${p.skill_count} skills)`);
  }
  
  if (report.issues.length > 0) {
    console.log('------------------------------------------------------------');
    console.log(' DETECTED ISSUES:');
    for (const issue of report.issues) {
      console.log(`  [${issue.severity}] [${issue.issue_code}] ${issue.target_id}: ${issue.message}`);
    }
  }
  
  console.log('============================================================\n');
}

process.exit(report.is_budget_healthy ? 0 : 1);
