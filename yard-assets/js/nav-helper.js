// Navigation helper for YARD docs
// Adds persistent navigation links, fixes sidebar navigation, and theme toggle

(function() {
  'use strict';

  // Calculate root path for assets
  function getRootPath() {
    var path = window.location.pathname;
    var rootPath = '';

    if (path.includes('/Lich/')) {
      var parts = path.split('/').filter(function(p) { return p; });
      var docsIndex = parts.indexOf('lich-5-docs');
      if (docsIndex >= 0) {
        var subParts = parts.slice(docsIndex + 1);
        rootPath = '../'.repeat(subParts.length - 1);
      }
    }

    if (!rootPath && !path.endsWith('/index.html') && !path.endsWith('/')) {
      var pathParts = path.split('/').filter(function(p) { return p && p !== 'index.html'; });
      var docsIdx = pathParts.indexOf('lich-5-docs');
      if (docsIdx >= 0) {
        rootPath = '../'.repeat(pathParts.length - docsIdx - 2);
      }
    }

    return rootPath;
  }

  // Inject theme CSS
  function injectThemeCSS() {
    if (document.getElementById('theme-css')) return;

    var rootPath = getRootPath();
    var link = document.createElement('link');
    link.id = 'theme-css';
    link.rel = 'stylesheet';
    link.href = rootPath + 'css/theme.css';
    document.head.appendChild(link);
  }

  // Get saved theme or detect system preference
  function getPreferredTheme() {
    var saved = localStorage.getItem('yard-theme');
    if (saved) return saved;

    // Check system preference
    if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
      return 'dark';
    }
    return 'light';
  }

  // Apply theme
  function applyTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('yard-theme', theme);

    // Update button text
    var btn = document.getElementById('theme-toggle');
    if (btn) {
      btn.textContent = theme === 'dark' ? '☀️ Light' : '🌙 Dark';
      btn.title = 'Switch to ' + (theme === 'dark' ? 'light' : 'dark') + ' mode';
    }
  }

  // Toggle theme
  function toggleTheme() {
    var current = document.documentElement.getAttribute('data-theme') || 'light';
    var newTheme = current === 'dark' ? 'light' : 'dark';
    applyTheme(newTheme);
  }

  function addNavLinks() {
    var content = document.getElementById('content');
    if (!content) return;

    if (document.getElementById('quick-nav')) return;

    var rootPath = getRootPath();

    // Create nav element
    var nav = document.createElement('div');
    nav.id = 'quick-nav';
    nav.style.cssText = 'padding: 8px 15px; margin-bottom: 15px; border-radius: 4px; border: 1px solid #ddd; font-size: 14px; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 8px;';

    // Navigation links
    var links = document.createElement('div');
    links.innerHTML = '<a href="' + rootPath + 'index.html" style="margin-right: 15px; text-decoration: none;">Home</a> | ' +
                      '<a href="' + rootPath + '_index.html" style="margin-left: 15px; margin-right: 15px; text-decoration: none;">All Classes</a> | ' +
                      '<a href="' + rootPath + 'file.psm-reference.html" style="margin-left: 15px; text-decoration: none;">PSM Guide</a>';

    // Theme toggle button
    var themeBtn = document.createElement('button');
    themeBtn.id = 'theme-toggle';
    themeBtn.type = 'button';
    themeBtn.onclick = toggleTheme;

    nav.appendChild(links);
    nav.appendChild(themeBtn);

    content.insertBefore(nav, content.firstChild);

    // Set initial button state
    var currentTheme = document.documentElement.getAttribute('data-theme') || 'light';
    themeBtn.textContent = currentTheme === 'dark' ? '☀️ Light' : '🌙 Dark';
    themeBtn.title = 'Switch to ' + (currentTheme === 'dark' ? 'light' : 'dark') + ' mode';
  }

  // Fix sidebar navigation
  function fixSidebarNavigation() {
    var fullList = document.getElementById('full_list');
    if (!fullList) return;

    fullList.addEventListener('click', function(e) {
      var link = e.target.closest('a');
      if (link && link.href) {
        var href = link.getAttribute('href');
        if (href && !href.startsWith('#') && !href.startsWith('javascript:')) {
          e.preventDefault();
          e.stopPropagation();
          window.location.href = link.href;
        }
      }
    }, true);
  }

  function fixClassListLinks() {
    var listContent = document.getElementById('full_list_content') ||
                      document.querySelector('.full_list_content') ||
                      document.getElementById('full_list');

    if (!listContent) return;

    var observer = new MutationObserver(function(mutations) {
      mutations.forEach(function(mutation) {
        mutation.addedNodes.forEach(function(node) {
          if (node.nodeType === 1) {
            var links = node.querySelectorAll ? node.querySelectorAll('a[href]') : [];
            links.forEach(function(link) {
              ensureLinkWorks(link);
            });
          }
        });
      });
    });

    observer.observe(listContent, { childList: true, subtree: true });

    var existingLinks = listContent.querySelectorAll('a[href]');
    existingLinks.forEach(function(link) {
      ensureLinkWorks(link);
    });
  }

  function ensureLinkWorks(link) {
    var href = link.getAttribute('href');
    if (!href || href.startsWith('#') || href.startsWith('javascript:')) return;

    link.onclick = null;
    link.addEventListener('click', function(e) {
      e.stopPropagation();
    });
  }

  // Initialize
  function init() {
    injectThemeCSS();
    applyTheme(getPreferredTheme());
    addNavLinks();
    fixSidebarNavigation();
    fixClassListLinks();
  }

  // Run when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

  // Also run after delay for dynamic content
  setTimeout(function() {
    fixSidebarNavigation();
    fixClassListLinks();
  }, 500);

  // Listen for system theme changes
  if (window.matchMedia) {
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function(e) {
      // Only auto-switch if user hasn't manually set a preference
      if (!localStorage.getItem('yard-theme')) {
        applyTheme(e.matches ? 'dark' : 'light');
      }
    });
  }
})();
