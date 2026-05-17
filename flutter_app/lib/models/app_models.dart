enum AnalysisStatus { pending, processing, completed, error }

class AnalysisTopic {
  final String title;
  final String prompt;
  bool isSelected;
  bool isCustom;
  AnalysisStatus status;

  AnalysisTopic({
    required this.title,
    required this.prompt,
    this.isSelected = true,
    this.isCustom = false,
    this.status = AnalysisStatus.pending,
  });
}

class ComponentSelection {
  final String name;
  bool isSelected;

  ComponentSelection({required this.name, this.isSelected = true});
}

class TableSelection {
  final String name;
  bool isSelected;

  TableSelection({required this.name, this.isSelected = true});
}

class ReportSection {
  final String title;
  final String content;

  ReportSection({required this.title, required this.content});
}

class SchemaFilterConfig {
  final List<String> selectedTables;
  final bool includeViews;
  final bool includeIndexes;
  final bool includeTriggers;
  final bool includeSps;
  final bool includeConstraints;
  final bool includeSampleData;

  SchemaFilterConfig({
    required this.selectedTables,
    required this.includeViews,
    required this.includeIndexes,
    required this.includeTriggers,
    required this.includeSps,
    required this.includeConstraints,
    required this.includeSampleData,
  });
}
