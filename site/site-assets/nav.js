(function () {
  const NAV = [
    {
      section: "Overview",
      items: [
        { id: "overview", label: "Overview & Features", icon: "◈", href: "index.html" },
      ],
    },
    {
      section: "Documentation",
      items: [
        { id: "workflow", label: "Workflow", icon: "01", href: "workflow.html" },
        { id: "architecture", label: "Architecture & Structure", icon: "02", href: "architecture.html" },
      ],
    },
    {
      section: "Development",
      items: [
        { id: "getting-started", label: "Getting Started", icon: "→", href: "getting-started.html" },
        { id: "backends", label: "Backends", icon: "◇", href: "backends.html" },
        { id: "sync", label: "Sync Strategy", icon: "↻", href: "sync.html" },
      ],
    },
    {
      section: "Reference",
      items: [
        { id: "skills", label: "Skills & Commands", icon: "★", href: "skills.html" },
        { id: "challenges", label: "Challenges", icon: "⚠", href: "challenges.html" },
        { id: "dos-donts", label: "Dos & Don'ts", icon: "✓", href: "dos-donts.html" },
        { id: "understanding", label: "Check Yourself", icon: "?", href: "understanding.html" },
      ],
    },
  ];

  window.renderSidebar = function (activeId) {
    const root = document.getElementById("sidebar-root");
    if (!root) return;

    let html =
      '<div class="brand">' +
      '<div class="brand-icon"><span>F</span></div>' +
      '<div class="brand-text">' +
      "<strong>Flutter Starter</strong>" +
      "<small>Clean Architecture</small>" +
      "</div>" +
      "</div>" +
      '<nav class="nav">';

    NAV.forEach(function (group) {
      html += '<div class="nav-title">' + group.section + "</div>";

      group.items.forEach(function (item) {
        const activeAttr = item.id === activeId ? ' class="active"' : "";
        html +=
          '<a href="' + item.href + '"' + activeAttr + ">" +
          '<span class="nav-icon">' + item.icon + "</span>" +
          item.label +
          "</a>";
      });
    });

    html += "</nav>";
    root.innerHTML = html;
  };
})();
