// provider_logo.dart — company logo for a bill's provider, falling back to
// the category tile.
// ------------------------------------------------------------------------
// Source order: Logo.dev when LOGO_DEV_TOKEN is set at build time, else
// unavatar.io (keyless, sends CORS headers, 404s on unknown domains). Both
// work under CanvasKit; favicon endpoints without CORS headers do not.
// Only the website domain is ever sent to the logo service.
//
// Geometry matches CategoryTile (radius 0.22 x size) so the two align in
// mixed lists. The category tile paints first; the logo fades in over it.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'category_icons.dart';

const _logoDevToken = String.fromEnvironment('LOGO_DEV_TOKEN');

const Map<String, String> _curatedDomains = {
  'ohio edison': 'firstenergycorp.com',
  'columbia gas': 'columbiagasohio.com',
  'spectrum internet': 'spectrum.com',
  'spectrum': 'spectrum.com',
  'verizon wireless': 'verizon.com',
  'verizon': 'verizon.com',
  'netflix': 'netflix.com',
  'spotify': 'spotify.com',
  'hulu': 'hulu.com',
  'disney+': 'disneyplus.com',
  'amazon prime': 'amazon.com',
  'youtube premium': 'youtube.com',
  'apple': 'apple.com',
  'icloud': 'apple.com',
  'at&t': 'att.com',
  't-mobile': 't-mobile.com',
  'comcast': 'xfinity.com',
  'xfinity': 'xfinity.com',
  'geico': 'geico.com',
  'state farm': 'statefarm.com',
  'progressive': 'progressive.com',
  'planet fitness': 'planetfitness.com',
};

/// Known provider → website, keyed by lowercased name. Unknown names keep
/// the category tile; nothing is guessed.
String? curatedDomainFor(String name) => _curatedDomains[name.trim().toLowerCase()];

/// Tried in order. unavatar's default source often returns .ico favicons,
/// which CanvasKit cannot decode; its /google/ source always returns PNG.
List<String> _logoUrls(String domain) => [
      if (_logoDevToken.isNotEmpty)
        'https://img.logo.dev/$domain?token=$_logoDevToken&size=128&format=png',
      'https://unavatar.io/$domain?fallback=false',
      'https://unavatar.io/google/$domain?fallback=false',
    ];

const _missPrefix = 'logo_miss_v2_';

/// Session + 7-day persisted memory of domains that had no usable logo.
class _LogoMisses {
  static final Set<String> _session = {};
  static final Map<String, int> _sourceFor = {};
  static Set<String>? _persisted;

  static Future<void> load() async {
    if (_persisted != null) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    _persisted = {};
    for (final k in prefs.getKeys().where((k) => k.startsWith('logo_miss_'))) {
      final at = DateTime.tryParse(prefs.getString(k) ?? '');
      if (k.startsWith(_missPrefix) && at != null && now.difference(at).inDays < 7) {
        _persisted!.add(k.substring(_missPrefix.length));
      } else {
        await prefs.remove(k);
      }
    }
  }

  static bool isMiss(String d) =>
      _session.contains(d) || (_persisted?.contains(d) ?? false);

  static Future<void> record(String d) async {
    if (!_session.add(d)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_missPrefix$d', DateTime.now().toIso8601String());
  }
}

class ProviderLogo extends StatefulWidget {
  const ProviderLogo({
    super.key,
    required this.name,
    this.domain,
    this.serviceType,
    this.size = 46,
    this.semanticLabel,
    this.decorative = true,
  });

  final String name;
  final String? domain;
  final String? serviceType;
  final double size;
  final String? semanticLabel;

  /// True when the payee name is rendered beside the logo.
  final bool decorative;

  @override
  State<ProviderLogo> createState() => _ProviderLogoState();
}

class _ProviderLogoState extends State<ProviderLogo> {
  bool _ready = _LogoMisses._persisted != null;

  @override
  void initState() {
    super.initState();
    if (!_ready) {
      _LogoMisses.load().then((_) {
        if (mounted) setState(() => _ready = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final radius = BorderRadius.circular(size * 0.22);
    final domain = widget.domain ?? curatedDomainFor(widget.name);
    final showImage = _ready && domain != null && !_LogoMisses.isMiss(domain);
    final urls = domain == null ? const <String>[] : _logoUrls(domain);
    final source = domain == null ? 0 : (_LogoMisses._sourceFor[domain] ?? 0);

    final tile = SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CategoryTile(
            text: widget.name,
            serviceType: widget.serviceType,
            dimension: size,
          ),
          if (showImage)
            Image.network(
              urls[source],
              key: ValueKey('$domain#$source'),
              fit: BoxFit.contain,
              gaplessPlayback: true,
              frameBuilder: (context, child, frame, sync) {
                if (frame == null && !sync) return const SizedBox.shrink();
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 150),
                  child: _LightInset(size: size, radius: radius, child: child),
                );
              },
              errorBuilder: (context, error, stack) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if ((_LogoMisses._sourceFor[domain] ?? 0) != source) {
                    if (mounted) setState(() {});
                    return;
                  }
                  if (source + 1 < urls.length) {
                    _LogoMisses._sourceFor[domain] = source + 1;
                  } else {
                    _LogoMisses.record(domain);
                  }
                  if (mounted) setState(() {});
                });
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
    );

    final clipped = ClipRRect(borderRadius: radius, child: tile);
    if (widget.decorative) return ExcludeSemantics(child: clipped);
    return Semantics(
      label: widget.semanticLabel ?? '${widget.name} logo',
      image: true,
      child: ExcludeSemantics(child: clipped),
    );
  }
}

/// Logos always sit on a light tile: many favicons are dark on transparent.
class _LightInset extends StatelessWidget {
  const _LightInset({required this.size, required this.radius, required this.child});
  final double size;
  final BorderRadius radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      padding: EdgeInsets.all(size * 0.14),
      child: child,
    );
  }
}
