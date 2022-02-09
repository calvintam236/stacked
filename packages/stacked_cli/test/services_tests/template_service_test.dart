import 'package:mockito/mockito.dart';
import 'package:stacked_cli/src/exceptions/invalid_stacked_structure_exception.dart';
import 'package:stacked_cli/src/locator.dart';
import 'package:stacked_cli/src/message_constants.dart';
import 'package:stacked_cli/src/models/template_models.dart';
import 'package:stacked_cli/src/services/template_service.dart';
import 'package:stacked_cli/src/templates/compiled_template_map.dart';
import 'package:stacked_cli/src/templates/template_constants.dart';
import 'package:test/test.dart';

import '../helpers/test_helper.dart';

TemplateService _getService() => TemplateService();

void main() {
  group('TemplateServiceTest -', () {
    setUp(() => registerServices());
    tearDown(() => locator.reset());

    group('renderContentForTemplate -', () {
      test(
          'When given content with string that has viewName, viewModelName and viewModelFileName, should return string with those values replaced',
          () {
        final content = '''
        {{viewName}}
        {{viewModelName}}
        {{viewModelFileName}}
    ''';
        final expected = '''
        NewView
        NewViewModel
        new_viewmodel.dart
    ''';

        final templateService = _getService();
        final result = templateService.renderContentForTemplate(
          content: content,
          templateName: 'view',
          name: 'new',
        );

        expect(result, expected);
      });

      test(
          'When given content with string that has viewName as orderDetails should return order_details_viewmodel.dart for viewModel',
          () {
        final content = '{{viewModelFileName}}';
        final expected = 'order_details_viewmodel.dart';

        final templateService = _getService();
        final result = templateService.renderContentForTemplate(
          content: content,
          templateName: 'view',
          name: 'orderDetails',
        );

        expect(result, expected);
      });
    });

    group('performFileModification -', () {
      test(
          'Given file content with STACKED identifier only, Should return template followed by STACKED in different lines',
          () {
        final service = _getService();
        final result = service.templateModificationFileContent(
          fileContent: 'STACKED',
          modificationTemplate: 'MaterialRoute(page: {{viewName}}),',
          modificationIdentifier: 'STACKED',
          viewName: 'details',
        );

        final expectedOutput = 'MaterialRoute(page: DetailsView),\nSTACKED';

        expect(result, expectedOutput);
      });

      test(
          'Given modificationTemplate with $kTemplateViewFolderName and name orderDetails, Should return snake_case order_details',
          () {
        final service = _getService();
        final result = service.templateModificationFileContent(
          fileContent: 'STACKED',
          modificationTemplate: '{{$kTemplateViewFolderName}}',
          modificationIdentifier: 'STACKED',
          viewName: 'orderDetails',
        );

        final expectedOutput = 'order_details\nSTACKED';

        expect(result, expectedOutput);
      });

      test(
          'Given modificationTemplate with $kTemplateViewFileName and name orderDetails, Should return snake_case order_details_view.dart',
          () {
        final service = _getService();
        final result = service.templateModificationFileContent(
          fileContent: 'STACKED',
          modificationTemplate: '{{$kTemplateViewFileName}}',
          modificationIdentifier: 'STACKED',
          viewName: 'orderDetails',
        );

        final expectedOutput = 'order_details_view.dart\nSTACKED';

        expect(result, expectedOutput);
      });
    });

    group('getTemplateOutputPath -', () {
      test(
          'When given a path generic/generic.dart with viewName orderDetails, should return order_details/order_details.dart',
          () {
        final service = _getService();
        final result = service.getTemplateOutputPath(
          inputTemplatePath: 'generic/generic.dart',
          name: 'orderDetails',
        );
        expect(result, 'order_details/order_details.dart');
      });
    });

    group('writeOutTemplateFiles -', () {
      test('Given templateName view, should write 3 files to the fileSystem',
          () async {
        final fileService = getAndRegisterMockFileService();
        final service = _getService();
        await service.writeOutTemplateFiles(
          template: kCompiledStackedTemplates['view']!,
          templateName: 'view',
          name: 'Details',
        );

        verify(fileService.writeFile(
          file: anyNamed('file'),
          fileContent: anyNamed('fileContent'),
        )).called(3);
      });
    });

    group('modifyExistingFiles -', () {
      test(
          'Given the view template with a modification file for lib/app/app.dart, should check if the file exists',
          () async {
        final fileService = getAndRegisterMockFileService();
        final service = _getService();
        await service.modifyExistingFiles(
          template: kCompiledStackedTemplates['view']!,
          templateName: 'view',
        );
        verify(fileService.fileExists(filePath: 'lib/app/app.dart'));
      });

      test(
          'Given the view template with a modification file for lib/app/app.dart, should get file data if it exists',
          () async {
        final fileService = getAndRegisterMockFileService();
        final service = _getService();
        await service.modifyExistingFiles(
          template: kCompiledStackedTemplates['view']!,
          templateName: 'view',
        );
        verify(fileService.readFile(filePath: 'lib/app/app.dart'));
      });

      test(
          'Given the view template with a modification file for lib/app/app.dart, if the file does not exist, should throw the InvalidStackedStructure message',
          () async {
        getAndRegisterMockFileService(
          fileExistsResult: false,
        );
        final service = _getService();

        expect(
            () async => await service.modifyExistingFiles(
                  template: kCompiledStackedTemplates['view']!,
                  templateName: 'view',
                ),
            throwsA(
              predicate(
                (e) =>
                    e is InvalidStackedStructureException &&
                    e.message == kInvalidStackedStructureAppFile,
              ),
            ));
      });

      test(
          'Given the a template with a 3 file modifications, should check if the file exists 3 times',
          () async {
        final fileService = getAndRegisterMockFileService();
        final service = _getService();
        await service.modifyExistingFiles(
          template: StackedTemplate(templateFiles: [], modificationFiles: [
            ModificationFile(
              relativeModificationPath: 'lib',
              modificationIdentifier: 'lib',
              modificationTemplate: 'modificationTemplate',
              modificationProblemError: '',
            ),
            ModificationFile(
              relativeModificationPath: 'lib',
              modificationIdentifier: 'lib',
              modificationTemplate: 'modificationTemplate',
              modificationProblemError: '',
            ),
            ModificationFile(
              relativeModificationPath: 'lib',
              modificationIdentifier: 'lib',
              modificationTemplate: 'modificationTemplate',
              modificationProblemError: '',
            ),
          ]),
          templateName: 'view',
        );
        verify(fileService.fileExists(filePath: anyNamed('filePath')))
            .called(3);
      });
    });

    group('renderTemplate -', () {
      test(
          'When called with excludeRoutes true, should not check if any file exists',
          () async {
        final fileService = getAndRegisterMockFileService();
        final service = _getService();
        await service.renderTemplate(
          templateName: 'view',
          excludeRoute: true,
          name: 'noRouteView',
        );

        verifyNever(fileService.fileExists(filePath: anyNamed('filePath')));
      });
    });

    group('getTemplateRenderData -', () {
      test(
          'When given renderTemplates with no values and templateName stacked, should throw exception',
          () {
        final service = _getService();
        expect(
          () => service.getTemplateRenderData(
              templateName: 'stacked', testRenderFunctions: {}, name: ''),
          throwsA(
            predicate((e) => e is Exception),
          ),
        );
      });
      test(
          'When given renderTemplate snakeCase and templateName snakeCase, should convert the property to snake_case',
          () {
        final service = _getService();
        final result = service.getTemplateRenderData(
            templateName: 'snakeCase',
            name: 'stackedCli',
            testRenderFunctions: {
              'snakeCase': (recaseValue) => {
                    'name': recaseValue.snakeCase,
                  }
            });

        expect(result['name'], 'stacked_cli');
      });
    });
  });
}