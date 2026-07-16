(() => {
  "use strict";

  const config = window.APP_CONFIG;
  const elements = {
    panel: document.querySelector("#release-panel"),
    version: document.querySelector("#release-version"),
    badge: document.querySelector("#release-badge"),
    message: document.querySelector("#release-message"),
    meta: document.querySelector("#release-meta"),
    date: document.querySelector("#release-date"),
    size: document.querySelector("#release-size"),
    download: document.querySelector("#download-button"),
    downloadLabel: document.querySelector("#download-button span"),
    retry: document.querySelector("#retry-button"),
    year: document.querySelector("#current-year"),
  };

  if (!config || !config.githubOwner || !config.githubRepo) {
    showConfigurationError();
    return;
  }

  const repositoryUrl = `https://github.com/${encodeURIComponent(config.githubOwner)}/${encodeURIComponent(config.githubRepo)}`;
  const releasesUrl = `${repositoryUrl}/releases`;
  const latestReleaseApi = `https://api.github.com/repos/${encodeURIComponent(config.githubOwner)}/${encodeURIComponent(config.githubRepo)}/releases/latest`;

  document.querySelectorAll("[data-repository-link]").forEach((link) => {
    link.href = repositoryUrl;
  });
  document.querySelectorAll("[data-releases-link]").forEach((link) => {
    link.href = releasesUrl;
  });
  elements.year.textContent = String(new Date().getFullYear());
  elements.retry.addEventListener("click", loadLatestRelease);

  loadLatestRelease();

  async function loadLatestRelease() {
    setLoadingState();

    try {
      const response = await fetch(latestReleaseApi, {
        headers: {
          Accept: "application/vnd.github+json",
          "X-GitHub-Api-Version": "2022-11-28",
        },
        cache: "no-store",
      });

      if (response.status === 404) {
        showMissingRelease();
        return;
      }
      if (!response.ok) {
        throw new Error(`GitHub returned ${response.status}`);
      }

      const release = await response.json();
      const apk = selectApk(release.assets);
      if (!apk) {
        showReleaseWithoutApk(release);
        return;
      }

      showRelease(release, apk);
    } catch (error) {
      console.warn("Unable to load the latest GitHub release.", error);
      showLoadError();
    }
  }

  function selectApk(assets) {
    if (!Array.isArray(assets)) {
      return null;
    }

    const uploadedApks = assets.filter((asset) => {
      const name = typeof asset?.name === "string" ? asset.name : "";
      const isDebug = name.toLowerCase().includes("debug");
      return (
        asset?.state === "uploaded" &&
        name.toLowerCase().endsWith(".apk") &&
        (config.allowDebugApk || !isDebug)
      );
    });

    const preferred = (config.preferredApkNames || []).map((name) =>
      String(name).toLowerCase(),
    );
    return (
      uploadedApks.find((asset) => preferred.includes(asset.name.toLowerCase())) ||
      uploadedApks[0] ||
      null
    );
  }

  function setLoadingState() {
    elements.panel.dataset.state = "loading";
    elements.panel.setAttribute("aria-busy", "true");
    elements.version.textContent = "Checking GitHub…";
    elements.badge.textContent = "Live";
    elements.message.textContent = "Looking for the newest Android package.";
    elements.meta.hidden = true;
    elements.retry.hidden = true;
    disableDownload("Checking latest version…");
  }

  function showRelease(release, apk) {
    elements.panel.dataset.state = "success";
    elements.panel.setAttribute("aria-busy", "false");
    elements.version.textContent = release.tag_name || release.name || "Latest version";
    elements.badge.textContent = "Ready";
    elements.message.textContent = "Verified against the latest published GitHub Release.";
    elements.date.textContent = formatDate(release.published_at || release.created_at);
    elements.size.textContent = formatBytes(apk.size);
    elements.meta.hidden = false;
    elements.retry.hidden = true;
    elements.download.href = apk.browser_download_url;
    elements.download.setAttribute("download", "");
    elements.download.removeAttribute("aria-disabled");
    elements.downloadLabel.textContent = `Download ${release.tag_name || "latest APK"}`;
  }

  function showMissingRelease() {
    elements.panel.dataset.state = "missing";
    elements.panel.setAttribute("aria-busy", "false");
    elements.version.textContent = "First release not published yet";
    elements.badge.textContent = "Pending";
    elements.message.textContent =
      "Create the GitHub repository and publish a release with a signed APK. This page will update automatically.";
    elements.meta.hidden = true;
    elements.retry.hidden = false;
    disableDownload("APK not available yet");
  }

  function showReleaseWithoutApk(release) {
    elements.panel.dataset.state = "missing";
    elements.panel.setAttribute("aria-busy", "false");
    elements.version.textContent = release.tag_name || release.name || "Latest release";
    elements.badge.textContent = "No APK";
    elements.message.textContent =
      "The latest release exists, but it does not contain a non-debug Android APK.";
    elements.date.textContent = formatDate(release.published_at || release.created_at);
    elements.size.textContent = "Not available";
    elements.meta.hidden = false;
    elements.retry.hidden = false;
    disableDownload("APK missing from release");
  }

  function showLoadError() {
    elements.panel.dataset.state = "error";
    elements.panel.setAttribute("aria-busy", "false");
    elements.version.textContent = "Could not check GitHub";
    elements.badge.textContent = "Offline";
    elements.message.textContent =
      "The newest version could not be verified. Try again or open GitHub Releases.";
    elements.meta.hidden = true;
    elements.retry.hidden = false;
    disableDownload("Latest version unavailable");
  }

  function showConfigurationError() {
    elements.panel.dataset.state = "error";
    elements.panel.setAttribute("aria-busy", "false");
    elements.version.textContent = "Repository not configured";
    elements.badge.textContent = "Setup";
    elements.message.textContent = "Add the GitHub owner and repository in config.js.";
    elements.meta.hidden = true;
    elements.retry.hidden = true;
    disableDownload("Configure GitHub first");
  }

  function disableDownload(label) {
    elements.download.removeAttribute("href");
    elements.download.removeAttribute("download");
    elements.download.setAttribute("aria-disabled", "true");
    elements.downloadLabel.textContent = label;
  }

  function formatDate(value) {
    if (!value) {
      return "Unknown";
    }
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
      return "Unknown";
    }
    return new Intl.DateTimeFormat(undefined, {
      day: "numeric",
      month: "short",
      year: "numeric",
    }).format(date);
  }

  function formatBytes(value) {
    const bytes = Number(value);
    if (!Number.isFinite(bytes) || bytes < 0) {
      return "Unknown";
    }
    if (bytes < 1024) {
      return `${bytes} B`;
    }
    const units = ["KB", "MB", "GB"];
    let amount = bytes / 1024;
    let unit = units[0];
    for (let index = 1; index < units.length && amount >= 1024; index += 1) {
      amount /= 1024;
      unit = units[index];
    }
    return `${amount >= 10 ? amount.toFixed(1) : amount.toFixed(2)} ${unit}`;
  }
})();
