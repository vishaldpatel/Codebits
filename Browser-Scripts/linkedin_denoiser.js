// ==UserScript==
// @name         LinkedIn Denoiser
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  This script removes promoted, suggested, and social media slop to leave behind posts, reposts, and comments by connections.
// @include        https://www.linkedin.com/
// @include      https://www.linkedin.com/feed/
// @run-at       document-body
// ==/UserScript==

(function() {
    'use strict';
    function processAndRemoveElements(rootNode = document) {
        const pTags = rootNode.getElementsByTagName('p');
        const elementsToRemove = new Set();

        for (let i = 0; i < pTags.length; i++) {
            const p = pTags[i];
            const spans = p.getElementsByTagName('span');

            for (let j = 0; j < spans.length; j++) {
                const span = spans[j];
                const isPromoted =
                      span.textContent.includes('Suggested') ||
                      span.textContent.includes('Promoted');
                // Get rid of "promoted"
                if (isPromoted) {
                    const targetDiv = p.closest('div[data-display-contents="true"]');
                    if (targetDiv && targetDiv.parentElement) {
                        elementsToRemove.add(targetDiv.parentElement);
                    }
                    break;
                }

                // Get rid of social slop
                const hasNoAttributes = span.attributes.length === 0;
                const hasAnchor = span.getElementsByTagName('a').length > 0;
                const hasNestedSpan = span.getElementsByTagName('span').length > 0;
                const hasText =
                      span.textContent.includes('likes this') ||
                      span.textContent.includes('supports this') ||
                      span.textContent.includes('finds this insightful') ||
                      span.textContent.includes('loves this') ||
                      span.textContent.includes('celebrates this') ||
                      span.textContent.includes('follows this Page') ||
                      span.textContent.includes('finds this funny');

                if (hasNoAttributes && hasAnchor && hasNestedSpan && hasText) {
                    const targetDiv = p.closest('div[data-display-contents="true"]');
                    if (targetDiv && targetDiv.parentElement) {
                        elementsToRemove.add(targetDiv.parentElement);
                    }
                    break;
                }
            }
        }

        // Remove elements from DOM
        console.log(`Elements to remove: ${elementsToRemove.length}`);
        elementsToRemove.forEach(el => el.remove());
    }

    // 1. Run once on initial page load
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => processAndRemoveElements());
    } else {
        processAndRemoveElements();
    }

    // 2. Watch for newly appended nodes (infinite scroll, AJAX updates)
    const observer = new MutationObserver((mutations) => {
        let hasNewNodes = false;

        for (const mutation of mutations) {
            if (mutation.addedNodes.length > 0) {
                hasNewNodes = true;
                break;
            }
        }

        if (hasNewNodes) {
            processAndRemoveElements();
        }
    });

    observer.observe(document.body, {
        childList: true,
        subtree: true
    });
})();
