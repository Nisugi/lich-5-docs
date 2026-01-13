// Navigation helper for YARD docs
// Adds persistent navigation links and fixes sidebar navigation issues

(function() {
  'use strict';

  function addNavLinks() {
    // Find the content area
    var content = document.getElementById('content');
    if (!content) return;

    // Check if we already added the nav
    if (document.getElementById('quick-nav')) return;

    // Calculate the relative path to root
    var depth = (window.location.pathname.match(/\//g) || []).length;
    var rootPath = '';

    // Check if we're in a subdirectory
    var path = window.location.pathname;
    if (path.includes('/Lich/')) {
      // Count depth after /lich-5-docs/
      var parts = path.split('/').filter(p => p);
      var docsIndex = parts.indexOf('lich-5-docs');
      if (docsIndex >= 0) {
        var subParts = parts.slice(docsIndex + 1);
        rootPath = '../'.repeat(subParts.length - 1);
      }
    }

    // If rootPath is empty and we're not at root, calculate from depth
    if (!rootPath && !path.endsWith('/index.html') && !path.endsWith('/')) {
      var pathParts = path.split('/').filter(p => p && p !== 'index.html');
      var docsIdx = pathParts.indexOf('lich-5-docs');
      if (docsIdx >= 0) {
        rootPath = '../'.repeat(pathParts.length - docsIdx - 2);
      }
    }

    // Create nav element
    var nav = document.createElement('div');
    nav.id = 'quick-nav';
    nav.style.cssText = 'background: #f8f9fa; padding: 8px 15px; margin-bottom: 15px; border-radius: 4px; border: 1px solid #ddd; font-size: 14px;';
    nav.innerHTML = '<a href="' + rootPath + 'index.html" style="margin-right: 15px; color: #0066cc; text-decoration: none;">Home</a> | ' +
                    '<a href="' + rootPath + '_index.html" style="margin-left: 15px; margin-right: 15px; color: #0066cc; text-decoration: none;">All Classes</a> | ' +
                    '<a href="' + rootPath + 'file.psm-reference.html" style="margin-left: 15px; color: #0066cc; text-decoration: none;">PSM Guide</a>';

    // Insert at the beginning of content
    content.insertBefore(nav, content.firstChild);
  }

  // Fix sidebar navigation - YARD's default JS sometimes prevents link clicks
  function fixSidebarNavigation() {
    var fullList = document.getElementById('full_list');
    if (!fullList) return;

    // Use event delegation on the sidebar container
    fullList.addEventListener('click', function(e) {
      var link = e.target.closest('a');
      if (link && link.href) {
        // Check if this is an internal link that should navigate
        var href = link.getAttribute('href');
        if (href && !href.startsWith('#') && !href.startsWith('javascript:')) {
          // Force navigation by setting window.location
          e.preventDefault();
          e.stopPropagation();
          window.location.href = link.href;
        }
      }
    }, true); // Use capture phase to intercept before YARD's handlers
  }

  // Also fix any links in the class list content area
  function fixClassListLinks() {
    // Find the class list content div
    var listContent = document.getElementById('full_list_content') ||
                      document.querySelector('.full_list_content') ||
                      document.getElementById('full_list');

    if (!listContent) return;

    // Observe for dynamically loaded content
    var observer = new MutationObserver(function(mutations) {
      mutations.forEach(function(mutation) {
        mutation.addedNodes.forEach(function(node) {
          if (node.nodeType === 1) { // Element node
            var links = node.querySelectorAll ? node.querySelectorAll('a[href]') : [];
            links.forEach(function(link) {
              ensureLinkWorks(link);
            });
          }
        });
      });
    });

    observer.observe(listContent, { childList: true, subtree: true });

    // Fix existing links
    var existingLinks = listContent.querySelectorAll('a[href]');
    existingLinks.forEach(function(link) {
      ensureLinkWorks(link);
    });
  }

  function ensureLinkWorks(link) {
    var href = link.getAttribute('href');
    if (!href || href.startsWith('#') || href.startsWith('javascript:')) return;

    // Remove any existing click handlers that might prevent navigation
    link.onclick = null;

    // Add our own handler
    link.addEventListener('click', function(e) {
      e.stopPropagation();
      // Allow default behavior (navigation) to proceed
    });
  }

  // Run when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      addNavLinks();
      fixSidebarNavigation();
      fixClassListLinks();
    });
  } else {
    addNavLinks();
    fixSidebarNavigation();
    fixClassListLinks();
  }

  // Also run after a short delay to catch dynamically loaded content
  setTimeout(function() {
    fixSidebarNavigation();
    fixClassListLinks();
  }, 500);
})();
