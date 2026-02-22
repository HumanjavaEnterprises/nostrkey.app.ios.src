/**
 * ios-polyfill.js
 *
 * Drop-in replacement for the browser extension API namespace.
 * Must be loaded BEFORE any bundled extension JS (background.build.js,
 * sidepanel.build.js, etc.).
 *
 * The extension's browser-polyfill.js checks:
 *   typeof browser !== 'undefined' ? browser : chrome
 * By defining window.browser here, the polyfill picks up our iOS
 * implementation automatically — zero changes to the bundled JS.
 */
(function () {
    'use strict';

    // Guard: don't run if a real browser namespace exists
    if (typeof window.browser !== 'undefined' && window.browser.runtime &&
        typeof window.browser.runtime.sendMessage === 'function') {
        return;
    }

    // ── Callback registry ───────────────────────────────────────────────
    var _callbacks = {};
    var _callbackId = 0;

    function nextId() {
        return String(++_callbackId);
    }

    /**
     * Resolve a pending JS callback. Called from Swift via evaluateJavaScript.
     * @param {string} id   - The callback ID
     * @param {string} json - JSON-encoded result (will be parsed)
     */
    window.__nostrkey_resolveCallback = function (id, json) {
        var cb = _callbacks[id];
        if (!cb) return;
        delete _callbacks[id];
        try {
            cb.resolve(JSON.parse(json));
        } catch (e) {
            cb.resolve(json);
        }
    };

    window.__nostrkey_rejectCallback = function (id, msg) {
        var cb = _callbacks[id];
        if (!cb) return;
        delete _callbacks[id];
        cb.reject(new Error(msg));
    };

    // ── Message listeners ───────────────────────────────────────────────
    var _messageListeners = [];

    /**
     * Deliver a routed message to onMessage listeners (background WebView).
     * Called from Swift via evaluateJavaScript.
     */
    window.__nostrkey_deliverMessage = function (callbackId, messageJson) {
        var message = JSON.parse(messageJson);
        var sender = { id: 'nostrkey-ios' };
        var responded = false;

        function sendResponse(response) {
            if (responded) return;
            responded = true;
            try {
                webkit.messageHandlers.nostrkey.postMessage({
                    action: 'sendResponse',
                    callbackId: callbackId,
                    data: JSON.stringify(response !== undefined ? response : null)
                });
            } catch (e) {
                console.error('[polyfill] sendResponse error:', e);
            }
        }

        for (var i = 0; i < _messageListeners.length; i++) {
            try {
                var result = _messageListeners[i](message, sender, sendResponse);
                if (result === true) {
                    // Listener will call sendResponse asynchronously — done
                    break;
                } else if (result && typeof result.then === 'function') {
                    result.then(function (r) {
                        if (!responded) sendResponse(r);
                    }).catch(function () {
                        if (!responded) sendResponse(undefined);
                    });
                    break;
                }
            } catch (e) {
                console.error('[polyfill] onMessage listener error:', e);
            }
        }
    };

    // ── Storage change listeners ────────────────────────────────────────
    var _storageChangeListeners = [];

    window.__nostrkey_storageChanged = function (changesJson, areaName) {
        var changes = JSON.parse(changesJson);
        for (var i = 0; i < _storageChangeListeners.length; i++) {
            try {
                _storageChangeListeners[i](changes, areaName);
            } catch (e) {
                console.error('[polyfill] storage.onChanged error:', e);
            }
        }
    };

    // ── Bridge helper ───────────────────────────────────────────────────
    function bridgeCall(action, data) {
        return new Promise(function (resolve, reject) {
            var id = nextId();
            _callbacks[id] = { resolve: resolve, reject: reject };
            try {
                if (!window.webkit || !window.webkit.messageHandlers ||
                    !window.webkit.messageHandlers.nostrkey) {
                    throw new Error('iOS bridge not available');
                }
                var message = { action: action, callbackId: id };
                if (data !== undefined) {
                    message.data = data;
                }
                window.webkit.messageHandlers.nostrkey.postMessage(message);
            } catch (e) {
                delete _callbacks[id];
                reject(e);
            }
        });
    }

    // ── window.browser ──────────────────────────────────────────────────
    window.browser = {
        runtime: {
            sendMessage: function (msg) {
                return bridgeCall('sendMessage', JSON.stringify(msg));
            },

            onMessage: {
                addListener: function (fn) {
                    _messageListeners.push(fn);
                },
                removeListener: function (fn) {
                    var idx = _messageListeners.indexOf(fn);
                    if (idx >= 0) _messageListeners.splice(idx, 1);
                },
                hasListener: function (fn) {
                    return _messageListeners.indexOf(fn) >= 0;
                }
            },

            getURL: function (path) {
                // WKWebView loads from file:// with loadFileURL — use relative paths
                // or the base URL injected at runtime
                if (window.__nostrkey_baseURL) {
                    return window.__nostrkey_baseURL + path;
                }
                return path;
            },

            openOptionsPage: function () {
                try {
                    webkit.messageHandlers.nostrkey.postMessage({
                        action: 'navigateTo',
                        data: 'full_settings.html'
                    });
                } catch (e) {}
                return Promise.resolve();
            },

            get id() {
                return 'nostrkey-ios';
            }
        },

        storage: {
            local: {
                get: function (keys) {
                    return bridgeCall('storageGet',
                        JSON.stringify(keys !== undefined ? keys : null));
                },
                set: function (items) {
                    return bridgeCall('storageSet', JSON.stringify(items));
                },
                remove: function (keys) {
                    return bridgeCall('storageRemove',
                        JSON.stringify(Array.isArray(keys) ? keys : [keys]));
                },
                clear: function () {
                    return bridgeCall('storageClear');
                }
            },

            sync: null,

            onChanged: {
                addListener: function (fn) {
                    _storageChangeListeners.push(fn);
                },
                removeListener: function (fn) {
                    var idx = _storageChangeListeners.indexOf(fn);
                    if (idx >= 0) _storageChangeListeners.splice(idx, 1);
                },
                hasListener: function (fn) {
                    return _storageChangeListeners.indexOf(fn) >= 0;
                }
            }
        },

        tabs: {
            create: function (opts) {
                if (opts && opts.url) {
                    try {
                        webkit.messageHandlers.nostrkey.postMessage({
                            action: 'navigateTo',
                            data: opts.url
                        });
                    } catch (e) {}
                }
                return Promise.resolve({ id: 1 });
            },
            query: function () { return Promise.resolve([]); },
            remove: function () {
                // In the extension this closes a tab; in iOS, go home
                try {
                    webkit.messageHandlers.nostrkey.postMessage({
                        action: 'navigateTo',
                        data: 'sidepanel.html'
                    });
                } catch (e) {}
                return Promise.resolve();
            },
            update: function () { return Promise.resolve({}); },
            get: function () { return Promise.resolve({ id: 1, url: '' }); },
            getCurrent: function () { return Promise.resolve({ id: 1, url: '' }); },
            sendMessage: function (_tabId, msg) {
                return bridgeCall('sendMessage', JSON.stringify(msg));
            }
        }
    };

    // Provide chrome namespace too (some code checks chrome directly)
    if (typeof window.chrome === 'undefined') {
        window.chrome = window.browser;
    }

    // ── Clipboard override ──────────────────────────────────────────────
    // file:// URLs aren't a secure context, so navigator.clipboard may
    // not be available. Override/provide it via the iOS bridge.
    try {
        var _clipboard = {
            writeText: function (text) {
                try {
                    webkit.messageHandlers.nostrkey.postMessage({
                        action: 'copyToClipboard',
                        data: text
                    });
                } catch (e) {
                    console.error('[polyfill] clipboard error:', e);
                }
                return Promise.resolve();
            },
            readText: function () {
                return Promise.reject(new Error('readText not supported'));
            }
        };

        if (!navigator.clipboard || !navigator.clipboard.writeText) {
            Object.defineProperty(navigator, 'clipboard', {
                value: _clipboard,
                writable: true,
                configurable: true
            });
        } else {
            // Wrap existing clipboard to also go through bridge
            var _origWriteText = navigator.clipboard.writeText.bind(navigator.clipboard);
            navigator.clipboard.writeText = function (text) {
                try {
                    webkit.messageHandlers.nostrkey.postMessage({
                        action: 'copyToClipboard',
                        data: text
                    });
                    return Promise.resolve();
                } catch (e) {
                    return _origWriteText(text);
                }
            };
        }
    } catch (e) {
        // Ignore clipboard setup errors
    }

    // ── window.close() override ────────────────────────────────────────
    // Sub-pages (Settings, Vault, etc.) call window.close() to dismiss
    // themselves. In a WebView there's no tab to close — navigate back
    // to the main sidepanel instead.
    window.close = function () {
        try {
            webkit.messageHandlers.nostrkey.postMessage({
                action: 'navigateTo',
                data: 'sidepanel.html'
            });
        } catch (e) {}
    };

    // ── QR code scanning ──────────────────────────────────────────────
    window.__nostrkey_scanQR = function () {
        return bridgeCall('scanQR');
    };

    // Wire the scan button once the DOM is ready
    document.addEventListener('DOMContentLoaded', function () {
        var scanBtn = document.getElementById('scan-qr-btn');
        if (!scanBtn) return;
        // Only reveal on iOS (webkit bridge exists)
        try {
            if (window.webkit && window.webkit.messageHandlers &&
                window.webkit.messageHandlers.nostrkey) {
                scanBtn.classList.remove('hidden');
            }
        } catch (e) { return; }

        scanBtn.addEventListener('click', function () {
            scanBtn.disabled = true;
            window.__nostrkey_scanQR().then(function (text) {
                var keyInput = document.getElementById('edit-profile-key');
                if (keyInput && text) {
                    keyInput.value = text;
                    keyInput.type = 'text';
                    keyInput.dispatchEvent(new Event('input', { bubbles: true }));
                }
            }).catch(function () {
                // Scan cancelled or failed — silently ignore
            }).finally(function () {
                scanBtn.disabled = false;
            });
        });
    });

    console.log('[NostrKey iOS] polyfill loaded');
})();
