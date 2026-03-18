import { PHASES } from './constants.js';
import { parseYamlMeta } from './parsers.js';

export async function loadBranches() {
  const res = await fetch('data/branches.json');
  if (!res.ok) throw new Error('No branches.json found');
  return res.json();
}

export async function loadBranch(branch) {
  const indexRes = await fetch(`data/${branch}/_index.json`);
  if (!indexRes.ok) throw new Error('No workflow data for this branch');
  const yamlPaths = await indexRes.json();

  const filesByPhase = {};
  yamlPaths.forEach(p => {
    const rel = p.replace('workflows/', '');
    for (const phase of PHASES) {
      if (rel.startsWith(phase.prefix)) {
        (filesByPhase[phase.idx] = filesByPhase[phase.idx] || []).push(p);
        break;
      }
    }
  });

  const phases = {};
  for (const idx of Object.keys(filesByPhase).map(Number).sort()) {
    const paths = filesByPhase[idx];
    const contents = await Promise.all(
      paths.map(p => fetch(`data/${branch}/${p}`).then(r => r.text()))
    );
    phases[idx] = contents.map((text, i) => {
      const meta = parseYamlMeta(text);
      meta._stem = paths[i].split('/').pop().replace('.yaml', '');
      meta._path = paths[i];
      return meta;
    });
  }
  return phases;
}

export async function loadWorkflowYaml(branch, yamlPath) {
  const res = await fetch(`data/${branch}/${yamlPath}`);
  if (!res.ok) throw new Error(`Could not load ${yamlPath}`);
  return res.text();
}
