<?php

namespace App\Http\Controllers;

use App\Models\Categories;
use App\Models\CountryMaster;
use App\Models\Divisions;
use App\Models\GlobalFunction;
use App\Models\Hashtags;
use App\Models\StateMaster;
use App\Models\SubCategories;
use App\Models\Topics;
use App\Services\ExcelImportService;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ExcelImportController extends Controller
{
    /**
     * Download sample CSV template for the given section
     */
    public function downloadSample(string $type): StreamedResponse
    {
        $samples = [
            'categories' => [
                'filename' => 'categories_sample.csv',
                'headers' => ['Category Name'],
                'rows' => [
                    ['Exam'],
                    ['School'],
                    ['Medical'],
                    ['Engineering'],
                ],
            ],
            'sub-categories' => [
                'filename' => 'sub_categories_sample.csv',
                'headers' => ['Category Name', 'Sub Category Name'],
                'rows' => [
                    ['Exam', 'UPSC'],
                    ['Exam', 'SSC'],
                    ['School', 'CBSE'],
                    ['Medical', 'NEET'],
                ],
            ],
            'divisions' => [
                'filename' => 'divisions_sample.csv',
                'headers' => ['Category Name', 'Sub Category Name', 'Division Name'],
                'rows' => [
                    ['Exam', 'UPSC', 'Prelims'],
                    ['Exam', 'UPSC', 'Mains'],
                    ['School', 'CBSE', 'Class 10'],
                    ['School', 'CBSE', 'Class 12'],
                ],
            ],
            'topics' => [
                'filename' => 'topics_sample.csv',
                'headers' => ['Category Name', 'Sub Category Name', 'Division Name', 'Topic Name'],
                'rows' => [
                    ['Exam', 'UPSC', 'Prelims', 'General Studies Paper 1'],
                    ['Exam', 'UPSC', 'Prelims', 'CSAT Paper 2'],
                    ['Exam', 'UPSC', 'Mains', 'Essay Paper'],
                    ['School', 'CBSE', 'Class 10', 'Mathematics'],
                    ['School', 'CBSE', '', 'English Literature'],
                ],
            ],
            'hashtags' => [
                'filename' => 'hashtags_sample.csv',
                'headers' => ['Hashtag'],
                'rows' => [
                    ['upsc'],
                    ['civilservices'],
                    ['education'],
                    ['cbseboard'],
                ],
            ],
            'countries' => [
                'filename' => 'countries_sample.csv',
                'headers' => ['Country Name'],
                'rows' => [
                    ['India'],
                    ['United States'],
                    ['United Kingdom'],
                    ['Canada'],
                ],
            ],
            'states' => [
                'filename' => 'states_sample.csv',
                'headers' => ['Country Name', 'State Name'],
                'rows' => [
                    ['India', 'Delhi'],
                    ['India', 'Maharashtra'],
                    ['India', 'Karnataka'],
                    ['India', 'Tamil Nadu'],
                ],
            ],
        ];

        $key = strtolower(trim($type));
        $data = $samples[$key] ?? $samples['categories'];

        return response()->streamDownload(function () use ($data) {
            $output = fopen('php://output', 'w');
            // Write UTF-8 BOM for Microsoft Excel compatibility
            fprintf($output, chr(0xEF) . chr(0xBB) . chr(0xBF));
            fputcsv($output, $data['headers']);
            foreach ($data['rows'] as $row) {
                fputcsv($output, $row);
            }
            fclose($output);
        }, $data['filename'], [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Cache-Control' => 'no-cache, no-store, must-revalidate',
            'Pragma' => 'no-cache',
            'Expires' => '0',
        ]);
    }

    /**
     * Parse uploaded file with validation
     */
    private function parseUploadedFile(Request $request): array
    {
        if (!$request->hasFile('file') || !$request->file('file')->isValid()) {
            throw new \Exception('Please select a valid Excel (.xlsx) or CSV (.csv) file.');
        }

        $file = $request->file('file');
        $ext = strtolower($file->getClientOriginalExtension());
        if (!in_array($ext, ['xlsx', 'xls', 'csv', 'txt', 'tsv'])) {
            throw new \Exception('Unsupported file format. Please upload an Excel (.xlsx) or CSV (.csv) file.');
        }

        $rows = ExcelImportService::parseFile($file->getRealPath(), $ext);
        if (count($rows) < 2) {
            throw new \Exception('The uploaded file contains no data rows to import.');
        }

        return $rows;
    }

    /**
     * Import Categories
     */
    public function importCategories(Request $request)
    {
        try {
            $rows = $this->parseUploadedFile($request);
            $headers = array_shift($rows);

            $colIndex = ExcelImportService::findColumnIndex($headers, ['categoryname', 'category', 'name'], 0);

            $imported = 0;
            $skipped = 0;

            foreach ($rows as $row) {
                $name = trim((string) ($row[$colIndex] ?? ''));
                if ($name === '') {
                    $skipped++;
                    continue;
                }

                $exists = Categories::whereRaw('LOWER(name) = ?', [strtolower($name)])->exists();
                if ($exists) {
                    $skipped++;
                    continue;
                }

                $item = new Categories();
                $item->name = $name;
                $item->status = 1;
                $item->save();
                $imported++;
            }

            return response()->json([
                'status' => true,
                'message' => "Import completed: {$imported} categories added" . ($skipped > 0 ? ", {$skipped} duplicates/empty skipped." : "."),
                'imported_count' => $imported,
                'skipped_count' => $skipped,
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'status' => false,
                'message' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Import Sub Categories
     */
    public function importSubCategories(Request $request)
    {
        try {
            $rows = $this->parseUploadedFile($request);
            $headers = array_shift($rows);

            $catCol = ExcelImportService::findColumnIndex($headers, ['categoryname', 'category'], 0);
            $subCatCol = ExcelImportService::findColumnIndex($headers, ['subcategoryname', 'subcategory', 'sub_category', 'name'], 1);

            $imported = 0;
            $skipped = 0;

            foreach ($rows as $row) {
                $catName = trim((string) ($row[$catCol] ?? ''));
                $subCatName = trim((string) ($row[$subCatCol] ?? ''));

                if ($catName === '' || $subCatName === '') {
                    $skipped++;
                    continue;
                }

                // Find or create Category
                $category = Categories::whereRaw('LOWER(name) = ?', [strtolower($catName)])->first();
                if (!$category) {
                    $category = new Categories();
                    $category->name = $catName;
                    $category->status = 1;
                    $category->save();
                }

                // Check duplicate SubCategory under this Category
                $exists = SubCategories::where('category_id', $category->id)
                    ->whereRaw('LOWER(name) = ?', [strtolower($subCatName)])
                    ->exists();

                if ($exists) {
                    $skipped++;
                    continue;
                }

                $sub = new SubCategories();
                $sub->category_id = $category->id;
                $sub->name = $subCatName;
                $sub->status = 1;
                $sub->save();
                $imported++;
            }

            return response()->json([
                'status' => true,
                'message' => "Import completed: {$imported} sub-categories added" . ($skipped > 0 ? ", {$skipped} duplicates/empty skipped." : "."),
                'imported_count' => $imported,
                'skipped_count' => $skipped,
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'status' => false,
                'message' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Import Divisions
     */
    public function importDivisions(Request $request)
    {
        try {
            $rows = $this->parseUploadedFile($request);
            $headers = array_shift($rows);

            $catCol = ExcelImportService::findColumnIndex($headers, ['categoryname', 'category'], 0);
            $subCatCol = ExcelImportService::findColumnIndex($headers, ['subcategoryname', 'subcategory', 'sub_category'], 1);
            $divCol = ExcelImportService::findColumnIndex($headers, ['divisionname', 'division', 'name'], 2);

            $imported = 0;
            $skipped = 0;

            foreach ($rows as $row) {
                $catName = trim((string) ($row[$catCol] ?? ''));
                $subCatName = trim((string) ($row[$subCatCol] ?? ''));
                $divName = trim((string) ($row[$divCol] ?? ''));

                if ($catName === '' || $subCatName === '' || $divName === '') {
                    $skipped++;
                    continue;
                }

                // Find or create Category
                $category = Categories::whereRaw('LOWER(name) = ?', [strtolower($catName)])->first();
                if (!$category) {
                    $category = new Categories();
                    $category->name = $catName;
                    $category->status = 1;
                    $category->save();
                }

                // Find or create SubCategory
                $subCategory = SubCategories::where('category_id', $category->id)
                    ->whereRaw('LOWER(name) = ?', [strtolower($subCatName)])
                    ->first();
                if (!$subCategory) {
                    $subCategory = new SubCategories();
                    $subCategory->category_id = $category->id;
                    $subCategory->name = $subCatName;
                    $subCategory->status = 1;
                    $subCategory->save();
                }

                // Check duplicate Division
                $exists = Divisions::where('category_id', $category->id)
                    ->where('sub_category_id', $subCategory->id)
                    ->whereRaw('LOWER(name) = ?', [strtolower($divName)])
                    ->exists();

                if ($exists) {
                    $skipped++;
                    continue;
                }

                $division = new Divisions();
                $division->category_id = $category->id;
                $division->sub_category_id = $subCategory->id;
                $division->name = $divName;
                $division->status = 1;
                $division->save();
                $imported++;
            }

            return response()->json([
                'status' => true,
                'message' => "Import completed: {$imported} divisions added" . ($skipped > 0 ? ", {$skipped} duplicates/empty skipped." : "."),
                'imported_count' => $imported,
                'skipped_count' => $skipped,
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'status' => false,
                'message' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Import Topics
     */
    public function importTopics(Request $request)
    {
        try {
            $rows = $this->parseUploadedFile($request);
            $headers = array_shift($rows);

            $hasDivisionCol = count($headers) >= 4;

            $catCol = ExcelImportService::findColumnIndex($headers, ['categoryname', 'category'], 0);
            $subCatCol = ExcelImportService::findColumnIndex($headers, ['subcategoryname', 'subcategory', 'sub_category'], 1);
            $divCol = $hasDivisionCol ? ExcelImportService::findColumnIndex($headers, ['divisionname', 'division'], 2) : -1;
            $topicCol = ExcelImportService::findColumnIndex($headers, ['topicname', 'topic', 'name'], $hasDivisionCol ? 3 : 2);

            $imported = 0;
            $skipped = 0;

            foreach ($rows as $row) {
                $catName = trim((string) ($row[$catCol] ?? ''));
                $subCatName = trim((string) ($row[$subCatCol] ?? ''));
                $topicName = trim((string) ($row[$topicCol] ?? ''));
                $divName = $divCol >= 0 ? trim((string) ($row[$divCol] ?? '')) : '';

                if ($catName === '' || $subCatName === '' || $topicName === '') {
                    $skipped++;
                    continue;
                }

                // Find or create Category
                $category = Categories::whereRaw('LOWER(name) = ?', [strtolower($catName)])->first();
                if (!$category) {
                    $category = new Categories();
                    $category->name = $catName;
                    $category->status = 1;
                    $category->save();
                }

                // Find or create SubCategory
                $subCategory = SubCategories::where('category_id', $category->id)
                    ->whereRaw('LOWER(name) = ?', [strtolower($subCatName)])
                    ->first();
                if (!$subCategory) {
                    $subCategory = new SubCategories();
                    $subCategory->category_id = $category->id;
                    $subCategory->name = $subCatName;
                    $subCategory->status = 1;
                    $subCategory->save();
                }

                // Find or create Division if specified
                $divisionId = null;
                if ($divName !== '') {
                    $division = Divisions::where('category_id', $category->id)
                        ->where('sub_category_id', $subCategory->id)
                        ->whereRaw('LOWER(name) = ?', [strtolower($divName)])
                        ->first();
                    if (!$division) {
                        $division = new Divisions();
                        $division->category_id = $category->id;
                        $division->sub_category_id = $subCategory->id;
                        $division->name = $divName;
                        $division->status = 1;
                        $division->save();
                    }
                    $divisionId = $division->id;
                }

                // Check duplicate Topic
                $topicQuery = Topics::where('category_id', $category->id)
                    ->where('sub_category_id', $subCategory->id)
                    ->whereRaw('LOWER(name) = ?', [strtolower($topicName)]);

                if ($divisionId !== null) {
                    $topicQuery->where('division_id', $divisionId);
                } else {
                    $topicQuery->whereNull('division_id');
                }

                if ($topicQuery->exists()) {
                    $skipped++;
                    continue;
                }

                $topic = new Topics();
                $topic->category_id = $category->id;
                $topic->sub_category_id = $subCategory->id;
                $topic->division_id = $divisionId;
                $topic->name = $topicName;
                $topic->status = 1;
                $topic->save();
                $imported++;
            }

            return response()->json([
                'status' => true,
                'message' => "Import completed: {$imported} topics added" . ($skipped > 0 ? ", {$skipped} duplicates/empty skipped." : "."),
                'imported_count' => $imported,
                'skipped_count' => $skipped,
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'status' => false,
                'message' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Import Hashtags
     */
    public function importHashtags(Request $request)
    {
        try {
            $rows = $this->parseUploadedFile($request);
            $headers = array_shift($rows);

            $colIndex = ExcelImportService::findColumnIndex($headers, ['hashtag', 'hashtags', 'tag', 'tags'], 0);

            $imported = 0;
            $skipped = 0;

            foreach ($rows as $row) {
                $rawTag = trim((string) ($row[$colIndex] ?? ''));
                $tag = ltrim($rawTag, '#@ ');
                $tag = trim($tag);

                if ($tag === '') {
                    $skipped++;
                    continue;
                }

                $exists = Hashtags::whereRaw('LOWER(hashtag) = ?', [strtolower($tag)])->exists();
                if ($exists) {
                    $skipped++;
                    continue;
                }

                $item = new Hashtags();
                $item->hashtag = $tag;
                $item->post_count = 0;
                $item->on_explore = 0;
                $item->save();
                $imported++;
            }

            return response()->json([
                'status' => true,
                'message' => "Import completed: {$imported} hashtags added" . ($skipped > 0 ? ", {$skipped} duplicates/empty skipped." : "."),
                'imported_count' => $imported,
                'skipped_count' => $skipped,
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'status' => false,
                'message' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Import Countries
     */
    public function importCountries(Request $request)
    {
        try {
            $rows = $this->parseUploadedFile($request);
            $headers = array_shift($rows);

            $colIndex = ExcelImportService::findColumnIndex($headers, ['countryname', 'country', 'name'], 0);

            $imported = 0;
            $skipped = 0;

            foreach ($rows as $row) {
                $name = trim((string) ($row[$colIndex] ?? ''));
                if ($name === '') {
                    $skipped++;
                    continue;
                }

                $exists = CountryMaster::whereRaw('LOWER(name) = ?', [strtolower($name)])->exists();
                if ($exists) {
                    $skipped++;
                    continue;
                }

                $country = new CountryMaster();
                $country->name = $name;
                $country->status = 1;
                $country->save();
                $imported++;
            }

            return response()->json([
                'status' => true,
                'message' => "Import completed: {$imported} countries added" . ($skipped > 0 ? ", {$skipped} duplicates/empty skipped." : "."),
                'imported_count' => $imported,
                'skipped_count' => $skipped,
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'status' => false,
                'message' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Import States
     */
    public function importStates(Request $request)
    {
        try {
            $rows = $this->parseUploadedFile($request);
            $headers = array_shift($rows);

            $countryCol = ExcelImportService::findColumnIndex($headers, ['countryname', 'country'], 0);
            $stateCol = ExcelImportService::findColumnIndex($headers, ['statename', 'state', 'name'], 1);

            $imported = 0;
            $skipped = 0;

            foreach ($rows as $row) {
                $countryName = trim((string) ($row[$countryCol] ?? ''));
                $stateName = trim((string) ($row[$stateCol] ?? ''));

                if ($countryName === '' || $stateName === '') {
                    $skipped++;
                    continue;
                }

                // Find or create Country
                $country = CountryMaster::whereRaw('LOWER(name) = ?', [strtolower($countryName)])->first();
                if (!$country) {
                    $country = new CountryMaster();
                    $country->name = $countryName;
                    $country->status = 1;
                    $country->save();
                }

                // Check duplicate State under this Country
                $exists = StateMaster::where('country_id', $country->id)
                    ->whereRaw('LOWER(name) = ?', [strtolower($stateName)])
                    ->exists();

                if ($exists) {
                    $skipped++;
                    continue;
                }

                $state = new StateMaster();
                $state->country_id = $country->id;
                $state->name = $stateName;
                $state->status = 1;
                $state->save();
                $imported++;
            }

            return response()->json([
                'status' => true,
                'message' => "Import completed: {$imported} states added" . ($skipped > 0 ? ", {$skipped} duplicates/empty skipped." : "."),
                'imported_count' => $imported,
                'skipped_count' => $skipped,
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'status' => false,
                'message' => $e->getMessage(),
            ]);
        }
    }
}
