import 'package:flutter/material.dart';

/// Display metadata for each FS knowledge-area domain. The `slug` values
/// must match the engine's domain slugs exactly (fs-exam-prep schema v1).
class DomainInfo {
  final String slug;
  final String name;
  final String blurb;
  final IconData icon;

  const DomainInfo({
    required this.slug,
    required this.name,
    required this.blurb,
    required this.icon,
  });
}

const List<DomainInfo> kDomains = [
  DomainInfo(
    slug: 'survey-computations',
    name: 'Survey Computations',
    blurb: 'COGO, traverses, curves, volumes · 17–26 questions',
    icon: Icons.calculate_outlined,
  ),
  DomainInfo(
    slug: 'boundary-law-and-real-property',
    name: 'Boundary Law',
    blurb: 'Hierarchy of calls, PLSS, water boundaries · 19–29 questions',
    icon: Icons.gavel_outlined,
  ),
  DomainInfo(
    slug: 'surveying-processes-and-methods',
    name: 'Surveying Processes',
    blurb: 'EDM, leveling, GNSS, traversing · 16–24 questions',
    icon: Icons.straighten_outlined,
  ),
  DomainInfo(
    slug: 'mapping-processes-and-methods',
    name: 'Mapping Methods',
    blurb: 'Contours, projections, LiDAR, GIS · 14–21 questions',
    icon: Icons.map_outlined,
  ),
  DomainInfo(
    slug: 'surveying-principles-geodesy',
    name: 'Geodesy',
    blurb: 'Datums, grid vs ground, heights · 13–20 questions',
    icon: Icons.public_outlined,
  ),
  DomainInfo(
    slug: 'business-concepts-ethics',
    name: 'Business & Ethics',
    blurb: 'Duties, sealing, contracts · 11–17 questions',
    icon: Icons.business_center_outlined,
  ),
  DomainInfo(
    slug: 'applied-math-statistics',
    name: 'Math & Statistics',
    blurb: 'Trig, error analysis, distributions · 10–15 questions',
    icon: Icons.functions_outlined,
  ),
];

DomainInfo domainInfo(String slug) =>
    kDomains.firstWhere((d) => d.slug == slug,
        orElse: () => DomainInfo(
            slug: slug, name: slug, blurb: '', icon: Icons.help_outline));
