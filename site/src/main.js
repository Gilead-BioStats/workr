import './style.css';
import { esc } from './utils.js';
import { loadBranches, loadBranch, loadWorkflowYaml } from './data.js';
import { buildPipeline, setPipelineBranch } from './pipeline.js';
import { buildPackagesTable, loadPackages, loadSnapshotDate } from './packages.js';
import { setFilter, applyFilters, resetFilters } from './filters.js';
import { buildDetailView } from './detail.js';

let currentBranch = '';
let currentPhases = null;
let compactMode = false;

function showTab(name) {
  document.getElementById('workflowsTab').style.display = name === 'workflows' ? '' : 'none';
  document.getElementById('packagesTab').style.display = name === 'packages' ? '' : 'none';
  document.querySelectorAll('.tab-btn').forEach(b => {
    const active = b.dataset.tab === name;
    b.classList.toggle('active', active);
    b.setAttribute('aria-selected', active);
  });
}

function renderWorkflows() {
  if (!currentPhases) return;
  const wTab = document.getElementById('workflowsTab');
  wTab.innerHTML = buildPipeline(currentPhases, compactMode);
  wTab.querySelectorAll('.filter-btn').forEach(btn => {
    btn.addEventListener('click', () => setFilter(btn.dataset.group));
  });
  resetFilters();
  updateToggleBtn();
}

function updateToggleBtn() {
  const btn = document.getElementById('viewToggle');
  if (btn) btn.textContent = compactMode ? 'Detailed' : 'Compact';
}

async function onBranchChange(branch) {
  if (!branch) return;
  currentBranch = branch;
  setPipelineBranch(branch);
  const wTab = document.getElementById('workflowsTab');
  const pTab = document.getElementById('packagesTab');
  wTab.innerHTML = '<div class="loading"><span class="spinner"></span> Loading workflows…</div>';
  pTab.innerHTML = '<div class="loading"><span class="spinner"></span> Loading packages…</div>';

  try {
    currentPhases = await loadBranch(branch);
    if (Object.keys(currentPhases).length === 0) {
      wTab.innerHTML = '<div class="loading">No workflows found on this branch</div>';
    } else {
      renderWorkflows();
      document.getElementById('searchInput').value = '';
    }
  } catch (err) {
    wTab.innerHTML = `<div class="error-msg">Error loading workflows: ${esc(err.message)}</div>`;
  }

  try {
    const [rows, snapDate] = await Promise.all([loadPackages(branch), loadSnapshotDate(branch)]);
    pTab.innerHTML = buildPackagesTable(rows, snapDate);
  } catch {
    pTab.innerHTML = '<div class="loading">No manifest.csv on this branch</div>';
  }
}

async function openDetail(yamlPath) {
  const modal = document.getElementById('detailModal');
  const content = document.getElementById('detailModalContent');
  modal.style.display = '';
  content.innerHTML = '<div class="loading"><span class="spinner"></span> Loading workflow…</div>';
  document.body.style.overflow = 'hidden';
  try {
    const text = await loadWorkflowYaml(currentBranch, yamlPath);
    content.innerHTML = buildDetailView(text, yamlPath);
    content.querySelector('.modal-close').addEventListener('click', closeDetail);
    const yamlToggle = content.querySelector('.yaml-toggle');
    if (yamlToggle) {
      yamlToggle.addEventListener('click', () => {
        const parsed = content.querySelector('.detail-parsed');
        const yaml = content.querySelector('.detail-yaml');
        const showing = yaml.style.display !== 'none';
        parsed.style.display = showing ? '' : 'none';
        yaml.style.display = showing ? 'none' : '';
        yamlToggle.textContent = showing ? 'Show YAML' : 'Show Details';
      });
    }
  } catch (err) {
    content.innerHTML = `<div class="error-msg">Error loading workflow: ${esc(err.message)}</div>`;
  }
}

function closeDetail() {
  document.getElementById('detailModal').style.display = 'none';
  document.getElementById('detailModalContent').innerHTML = '';
  document.body.style.overflow = '';
}

async function init() {
  const sel = document.getElementById('branchSelect');
  try {
    const branches = await loadBranches();
    sel.innerHTML = '<option value="">— select branch —</option>';
    const priority = ['dev', 'main', 'prod'];
    branches.sort((a, b) => {
      const ai = priority.indexOf(a), bi = priority.indexOf(b);
      if (ai !== -1 && bi !== -1) return ai - bi;
      if (ai !== -1) return -1;
      if (bi !== -1) return 1;
      return a.localeCompare(b);
    });
    branches.forEach(b => {
      const o = document.createElement('option');
      o.value = b; o.textContent = b;
      sel.appendChild(o);
    });
    sel.addEventListener('change', () => onBranchChange(sel.value));
    if (branches.includes('dev')) { sel.value = 'dev'; onBranchChange('dev'); }
  } catch (err) {
    sel.innerHTML = '<option value="">Error loading branches</option>';
    document.getElementById('workflowsTab').innerHTML =
      `<div class="error-msg">Could not load branch list: ${esc(err.message)}</div>`;
  }
}

// Wire up tabs
document.querySelectorAll('.tab-btn').forEach(btn => {
  btn.addEventListener('click', () => showTab(btn.dataset.tab));
});

// Wire up compact/detailed toggle
document.getElementById('viewToggle').addEventListener('click', () => {
  compactMode = !compactMode;
  renderWorkflows();
});

// Wire up search
document.getElementById('searchInput').addEventListener('input', applyFilters);

// Delegate info-button clicks on the workflows tab
document.getElementById('workflowsTab').addEventListener('click', (e) => {
  const btn = e.target.closest('.card-info-btn');
  if (btn && btn.dataset.path) {
    e.stopPropagation();
    openDetail(btn.dataset.path);
  }
});

// Close modal on overlay click or Escape
document.getElementById('detailModal').addEventListener('click', (e) => {
  if (e.target === e.currentTarget) closeDetail();
});
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && document.getElementById('detailModal').style.display !== 'none') {
    closeDetail();
  }
});

init();
