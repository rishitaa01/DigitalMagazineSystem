/* ============================================================
   Digital Magazine Management System — Client-side JS
   ============================================================ */

document.addEventListener('DOMContentLoaded', () => {
  initSidebarToggle();
  initSearchFilters();
  initDeleteConfirm();
  initFlashDismiss();
  initCharts();
});

/* --- Sidebar Toggle (Mobile) --- */
function initSidebarToggle() {
  const toggle = document.getElementById('sidebar-toggle');
  const sidebar = document.getElementById('sidebar');
  if (toggle && sidebar) {
    toggle.addEventListener('click', () => sidebar.classList.toggle('open'));
    document.addEventListener('click', (e) => {
      if (sidebar.classList.contains('open') &&
          !sidebar.contains(e.target) && e.target !== toggle) {
        sidebar.classList.remove('open');
      }
    });
  }
}

/* --- Client-side Table Search --- */
function initSearchFilters() {
  const liveSearch = document.getElementById('live-search');
  if (liveSearch) {
    liveSearch.addEventListener('input', (e) => {
      const q = e.target.value.toLowerCase();
      const rows = document.querySelectorAll('table tbody tr');
      rows.forEach(row => {
        const text = row.textContent.toLowerCase();
        row.style.display = text.includes(q) ? '' : 'none';
      });
    });
  }
}

/* --- Delete Confirmation --- */
function initDeleteConfirm() {
  document.querySelectorAll('.delete-form').forEach(form => {
    form.addEventListener('submit', (e) => {
      if (!confirm('Are you sure you want to delete this record? This action cannot be undone.')) {
        e.preventDefault();
      }
    });
  });
}

/* --- Flash Message Auto-dismiss --- */
function initFlashDismiss() {
  document.querySelectorAll('.flash').forEach(el => {
    setTimeout(() => {
      el.style.opacity = '0';
      el.style.transform = 'translateY(-10px)';
      setTimeout(() => el.remove(), 300);
    }, 4000);
  });
}

/* --- Chart.js Initialization --- */
function initCharts() {
  // Articles per Magazine — Bar Chart
  const barCtx = document.getElementById('articles-chart');
  if (barCtx && typeof Chart !== 'undefined') {
    const labels = JSON.parse(barCtx.dataset.labels || '[]');
    const values = JSON.parse(barCtx.dataset.values || '[]');
    new Chart(barCtx, {
      type: 'bar',
      data: {
        labels: labels,
        datasets: [{
          label: 'Articles',
          data: values,
          backgroundColor: [
            'rgba(108,99,255,0.7)', 'rgba(52,211,153,0.7)',
            'rgba(249,115,22,0.7)', 'rgba(59,130,246,0.7)',
            'rgba(168,85,247,0.7)', 'rgba(236,72,153,0.7)',
            'rgba(251,191,36,0.7)', 'rgba(20,184,166,0.7)'
          ],
          borderColor: [
            '#6c63ff', '#34d399', '#f97316', '#3b82f6',
            '#a855f7', '#ec4899', '#fbbf24', '#14b8a6'
          ],
          borderWidth: 2,
          borderRadius: 6
        }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          title: { display: true, text: 'Articles per Magazine', color: '#e8e8ed', font: { size: 14 } }
        },
        scales: {
          y: { beginAtZero: true, ticks: { color: '#9498b0', stepSize: 1 }, grid: { color: '#2a2d3e' } },
          x: { ticks: { color: '#9498b0', maxRotation: 45 }, grid: { display: false } }
        }
      }
    });
  }

  // Subscriptions by Month — Line Chart
  const lineCtx = document.getElementById('subscriptions-chart');
  if (lineCtx && typeof Chart !== 'undefined') {
    const labels = JSON.parse(lineCtx.dataset.labels || '[]');
    const values = JSON.parse(lineCtx.dataset.values || '[]');
    new Chart(lineCtx, {
      type: 'line',
      data: {
        labels: labels,
        datasets: [{
          label: 'Subscriptions',
          data: values,
          borderColor: '#6c63ff',
          backgroundColor: 'rgba(108,99,255,0.1)',
          fill: true,
          tension: 0.4,
          pointBackgroundColor: '#6c63ff',
          pointBorderColor: '#fff',
          pointRadius: 5,
          pointHoverRadius: 7
        }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          title: { display: true, text: 'Subscription Growth', color: '#e8e8ed', font: { size: 14 } }
        },
        scales: {
          y: { beginAtZero: true, ticks: { color: '#9498b0', stepSize: 1 }, grid: { color: '#2a2d3e' } },
          x: { ticks: { color: '#9498b0' }, grid: { display: false } }
        }
      }
    });
  }
}
