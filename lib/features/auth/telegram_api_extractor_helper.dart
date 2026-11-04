// This code for extracting Telegram API ID and API Hash from modern my.telegram.org DOM
import 'dart:convert';

/// Helper utility for extracting Telegram developer API credentials from my.telegram.org DOM structures.
class TelegramApiExtractorHelper {
  static const String myTelegramOrgAuthUrl = 'https://my.telegram.org/auth';
  static const String myTelegramOrgAppsUrl = 'https://my.telegram.org/apps';

  /// Modern JavaScript scanner targeting [data-copy], .creds > .cred, #stage_code, and #app_create_form
  static const String extractionScript = r'''
(function() {
  try {
    var apiId = null;
    var apiHash = null;

    // 1. Check data-copy attributes on modern elements
    var copyElements = document.querySelectorAll('[data-copy]');
    for (var i = 0; i < copyElements.length; i++) {
      var val = (copyElements[i].getAttribute('data-copy') || copyElements[i].innerText || '').trim();
      if (!apiId && /^\d{5,10}$/.test(val)) {
        apiId = parseInt(val, 10);
      }
      if (!apiHash && /^[0-9a-fA-F]{32}$/.test(val)) {
        apiHash = val;
      }
    }

    // 2. Check responsive credential containers (.creds > .cred)
    var credElements = document.querySelectorAll('.creds > .cred, .creds .cred, .cred');
    for (var j = 0; j < credElements.length; j++) {
      var text = (credElements[j].innerText || credElements[j].textContent || '').trim();
      var idMatch = text.match(/(?:App\s*api_id|api_id)[:\s]+(\d{5,10})/i) || text.match(/^(\d{5,10})$/);
      if (idMatch && !apiId) apiId = parseInt(idMatch[1], 10);
      var hashMatch = text.match(/(?:App\s*api_hash|api_hash)[:\s]+([0-9a-fA-F]{32})/i) || text.match(/^([0-9a-fA-F]{32})$/);
      if (hashMatch && !apiHash) apiHash = hashMatch[1];
    }

    // 3. Check table rows and form control groups
    var formGroups = document.querySelectorAll('.form-group, .control-group, tr');
    for (var k = 0; k < formGroups.length; k++) {
      var gText = formGroups[k].innerText || formGroups[k].textContent || '';
      if (/api_id/i.test(gText)) {
        var mId = gText.match(/(\d{5,10})/);
        if (mId && !apiId) apiId = parseInt(mId[1], 10);
      }
      if (/api_hash/i.test(gText)) {
        var mHash = gText.match(/([0-9a-fA-F]{32})/i);
        if (mHash && !apiHash) apiHash = mHash[1];
      }
    }

    // 4. Fallback search across entire document body text
    if (!apiId || !apiHash) {
      var bodyText = document.body ? (document.body.innerText || document.body.textContent || '') : '';
      var bodyIdMatch = bodyText.match(/(?:App\s*api_id|api_id)[:\s]+(\d{5,10})/i);
      if (bodyIdMatch && !apiId) apiId = parseInt(bodyIdMatch[1], 10);
      var bodyHashMatch = bodyText.match(/(?:App\s*api_hash|api_hash)[:\s]+([0-9a-fA-F]{32})/i);
      if (bodyHashMatch && !apiHash) apiHash = bodyHashMatch[1];
    }

    // 5. Detect page stage
    var stage = 'unknown';
    if (document.querySelector('#stage_code, #my_password, input[name="confirm_code"]')) {
      stage = 'waiting_code';
    } else if (document.querySelector('#app_create_form')) {
      stage = 'create_app';
      // Auto-populate create application form helper fields
      var form = document.querySelector('#app_create_form');
      var titleInput = form.querySelector('#app_title, input[name="app_title"]');
      var shortNameInput = form.querySelector('#app_short_name, input[name="app_short_name"]');
      if (titleInput && !titleInput.value) {
        titleInput.value = 'Infinity Vault';
        titleInput.dispatchEvent(new Event('input', { bubbles: true }));
        titleInput.dispatchEvent(new Event('change', { bubbles: true }));
      }
      if (shortNameInput && !shortNameInput.value) {
        shortNameInput.value = 'infvault' + Math.floor(1000 + Math.random() * 9000);
        shortNameInput.dispatchEvent(new Event('input', { bubbles: true }));
        shortNameInput.dispatchEvent(new Event('change', { bubbles: true }));
      }
    } else if (apiId && apiHash) {
      stage = 'extracted';
    } else if (window.location.href.indexOf('/apps') !== -1) {
      stage = 'apps_page';
    } else if (window.location.href.indexOf('/auth') !== -1) {
      stage = 'auth_page';
    }

    // Auto-navigate to /apps once logged in if on main menu
    if ((window.location.pathname === '/' || window.location.pathname === '/auth') && !apiId) {
      var appsLink = document.querySelector('a[href*="/apps"]');
      if (appsLink) {
        window.location.href = 'https://my.telegram.org/apps';
      }
    }

    var result = {
      apiId: apiId,
      apiHash: apiHash,
      stage: stage,
      url: window.location.href
    };

    if (apiId && apiHash && window.TelegramExtractor && window.TelegramExtractor.postMessage) {
      window.TelegramExtractor.postMessage(JSON.stringify(result));
    }

    return JSON.stringify(result);
  } catch (err) {
    return JSON.stringify({ error: err.toString() });
  }
})();
''';

  /// Parses and validates message string received from the JavaScript extractor channel
  static Map<String, dynamic>? parseExtractorMessage(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) return null;

      int? apiId;
      if (decoded['apiId'] is int) {
        apiId = decoded['apiId'] as int;
      } else if (decoded['apiId'] != null) {
        apiId = int.tryParse(decoded['apiId'].toString());
      }

      final apiHash = decoded['apiHash']?.toString().trim();
      final stage = decoded['stage']?.toString();

      final isValidHash = apiHash != null &&
          RegExp(r'^[0-9a-fA-F]{32}$').hasMatch(apiHash);
      final isValidId = apiId != null && apiId > 0;

      return {
        'apiId': isValidId ? apiId : null,
        'apiHash': isValidHash ? apiHash : null,
        'stage': stage ?? 'unknown',
        'isComplete': isValidId && isValidHash,
      };
    } catch (_) {
      return null;
    }
  }

  /// Parses raw HTML or plain text string to extract credentials (e.g. for offline testing or manual paste)
  static Map<String, dynamic>? extractFromTextOrHtml(String content) {
    if (content.trim().isEmpty) return null;

    int? apiId;
    String? apiHash;

    // Check [data-copy] attributes
    final dataCopyRegex = RegExp(r'''data-copy=["']([^"']+)["']''', caseSensitive: false);
    for (final match in dataCopyRegex.allMatches(content)) {
      final val = match.group(1)?.trim();
      if (val != null) {
        if (apiId == null && RegExp(r'^\d{5,10}$').hasMatch(val)) {
          apiId = int.tryParse(val);
        }
        if (apiHash == null && RegExp(r'^[0-9a-fA-F]{32}$').hasMatch(val)) {
          apiHash = val;
        }
      }
    }

    // Check .creds > .cred or text labels
    if (apiId == null) {
      final idMatch = RegExp(r'''(?:App\s*api_id|api_id)[^\d]{1,60}?(\d{5,10})\b''', caseSensitive: false)
          .firstMatch(content);
      if (idMatch != null) {
        apiId = int.tryParse(idMatch.group(1) ?? '');
      }
    }

    if (apiHash == null) {
      final hashMatch = RegExp(r'''(?:App\s*api_hash|api_hash)[^0-9a-fA-F]{1,60}?([0-9a-fA-F]{32})\b''', caseSensitive: false)
          .firstMatch(content);
      if (hashMatch != null) {
        apiHash = hashMatch.group(1);
      }
    }

    if (apiId != null && apiHash != null && RegExp(r'^[0-9a-fA-F]{32}$').hasMatch(apiHash)) {
      return {
        'apiId': apiId,
        'apiHash': apiHash,
      };
    }

    return null;
  }
}
