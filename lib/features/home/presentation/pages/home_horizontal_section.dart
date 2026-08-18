part of 'home_page.dart';

class _HorizontalSection extends StatelessWidget {
  const _HorizontalSection({
    required this.title,
    required this.action,
    required this.height,
    required this.children,
  });

  final String title;
  final String action;
  final double height;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
    child: Column(
      children: [
        SectionHeader(title: title, action: action, onAction: () {}),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: children.length,
            separatorBuilder: (_, _) => const SizedBox(width: 11),
            itemBuilder: (_, index) => children[index],
          ),
        ),
      ],
    ),
  );
}
