// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AppSideMenu extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final String? selectedRoute;
  final void Function(String route) onNavigate;


  final String appName;
  final IconData headerIcon;
  final String headerSubtitle;

  const AppSideMenu({
    super.key,
    required this.expanded,
    required this.onToggle,
    required this.selectedRoute,
    required this.onNavigate,
    this.appName = 'CustoPro',
    this.headerIcon = Icons.monetization_on,
    this.headerSubtitle = 'Menu',
  });

  static const Color _green = Color(0xFF428E2E);
  static const Color _bg = Colors.white;

  @override
  Widget build(BuildContext context) {
    final w = expanded ? 290.0 : 92.0;

    return Drawer(
      backgroundColor: _bg,
      width: w,
      child: SafeArea(
        child: Column(
          children: [
            _Header(
              expanded: expanded,
              onToggle: onToggle,
              appName: appName,
              subtitle: headerSubtitle,
              icon: headerIcon,
            ),

            const SizedBox(height: 10),

            
            AppMenuItem(
              expanded: expanded,
              icon: Icons.home_rounded,
              label: 'Home',
              route: '/home',
              selected: selectedRoute == '/home' || selectedRoute == null,
              onTap: onNavigate,
            ),
            AppMenuItem(
              expanded: expanded,
              icon: Icons.format_list_bulleted_add,
              label: 'Cadastrar Matéria-Prima',
              route: '/cadastro-mp',
              selected: selectedRoute == '/cadastro-mp',
              onTap: onNavigate,
            ),
            AppMenuItem(
              expanded: expanded,
              icon: Icons.assessment_rounded,
              label: 'Tabela Geral',
              route: '/tabela-geral',
              selected: selectedRoute == '/tabela-geral',
              onTap: onNavigate,
            ),
            AppMenuItem(
              expanded: expanded,
              icon: Icons.person,
              label: 'Perfil',
              route: '/perfil',
              selected: selectedRoute == '/perfil',
              onTap: onNavigate,
            ),
            AppMenuItem(
              expanded: expanded,
              icon: Icons.help_outline,
              label: 'Ajuda',
              route: '/ajuda',
              selected: selectedRoute == '/ajuda',
              onTap: onNavigate,
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: _green),
                    if (expanded) ...[
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Dica: use o botão acima para recolher o menu.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF2B2B2B)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final String appName;
  final String subtitle;
  final IconData icon;

  const _Header({
    required this.expanded,
    required this.onToggle,
    required this.appName,
    required this.subtitle,
    required this.icon,
  });

  static const Color _green = Color(0xFF428E2E);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _green.withOpacity(0.10),
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.06)),
        ),
      ),
      child: expanded
          ? Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        appName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2B2B2B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B6B6B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Recolher',
                  onPressed: onToggle,
                  icon: Icon(Icons.chevron_left, color: _green),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 44,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black.withOpacity(0.08)),
                    ),
                    child: Icon(Icons.chevron_right, color: _green),
                  ),
                ),
              ],
            ),
    );
  }
}

class AppMenuItem extends StatelessWidget {
  final bool expanded;
  final IconData icon;
  final String label;
  final String route;
  final bool selected;
  final void Function(String route) onTap;

  const AppMenuItem({
    super.key,
    required this.expanded,
    required this.icon,
    required this.label,
    required this.route,
    required this.selected,
    required this.onTap,
  });

  static const Color _green = Color(0xFF428E2E);

  @override
  Widget build(BuildContext context) {
    final bg = selected ? _green.withOpacity(0.12) : Colors.transparent;
    final iconColor = selected ? _green : const Color(0xFF2B2B2B);
    final textColor = selected ? _green : const Color(0xFF2B2B2B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onTap(route),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? 14 : 8,
              vertical: 12,
            ),
            child: expanded
                ? Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selected ? _green : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.black.withOpacity(0.08)),
                        ),
                        child: Icon(
                          icon,
                          color: selected ? Colors.white : iconColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.black.withOpacity(0.35)),
                    ],
                  )
                : Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected ? _green : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black.withOpacity(0.08)),
                      ),
                      child: Icon(
                        icon,
                        color: selected ? Colors.white : iconColor,
                        size: 22,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}