<?php

namespace App\Services;

use Exception;

class ExcelImportService
{
    /**
     * Parse an uploaded Excel (.xlsx, .xls) or CSV/TSV file into an array of rows.
     *
     * @param string $filePath
     * @param string $originalExtension
     * @return array
     * @throws Exception
     */
    public static function parseFile(string $filePath, string $originalExtension = ''): array
    {
        if (!file_exists($filePath) || !is_readable($filePath)) {
            throw new Exception('Uploaded file could not be read.');
        }

        $ext = strtolower(trim($originalExtension, '. '));
        if ($ext === '') {
            $ext = strtolower(pathinfo($filePath, PATHINFO_EXTENSION));
        }

        if (in_array($ext, ['csv', 'tsv', 'txt'])) {
            return self::parseCsv($filePath);
        }

        if (in_array($ext, ['xlsx', 'xls'])) {
            return self::parseXlsx($filePath);
        }

        // Try XLSX first, then fallback to CSV
        try {
            return self::parseXlsx($filePath);
        } catch (\Throwable $e) {
            return self::parseCsv($filePath);
        }
    }

    /**
     * Parse CSV or TSV file
     *
     * @param string $filePath
     * @return array
     * @throws Exception
     */
    public static function parseCsv(string $filePath): array
    {
        $handle = fopen($filePath, 'r');
        if ($handle === false) {
            throw new Exception('Failed to open CSV file.');
        }

        // Check and skip UTF-8 BOM if present
        $bom = fread($handle, 3);
        if ($bom !== "\xEF\xBB\xBF") {
            rewind($handle);
        }

        // Determine delimiter by reading the first non-empty line
        $firstLine = fgets($handle);
        rewind($handle);
        if ($bom === "\xEF\xBB\xBF") {
            fread($handle, 3);
        }

        $delimiter = ',';
        if ($firstLine !== false) {
            $commas = substr_count($firstLine, ',');
            $semis = substr_count($firstLine, ';');
            $tabs = substr_count($firstLine, "\t");
            if ($semis > $commas && $semis > $tabs) {
                $delimiter = ';';
            } elseif ($tabs > $commas && $tabs > $semis) {
                $delimiter = "\t";
            }
        }

        $rows = [];
        while (($data = fgetcsv($handle, 0, $delimiter)) !== false) {
            $trimmed = array_map(function ($val) {
                return trim((string) $val);
            }, $data);

            // Skip row if completely empty
            if (count(array_filter($trimmed, 'strlen')) > 0) {
                $rows[] = $trimmed;
            }
        }

        fclose($handle);
        return $rows;
    }

    /**
     * Parse XLSX file using SimpleXLSX
     *
     * @param string $filePath
     * @return array
     * @throws Exception
     */
    public static function parseXlsx(string $filePath): array
    {
        if (!class_exists(\Shuchkin\SimpleXLSX::class)) {
            $path = dirname(__DIR__, 2) . '/vendor/shuchkin/simplexlsx/src/SimpleXLSX.php';
            if (file_exists($path)) {
                require_once $path;
            } else {
                throw new Exception('XLSX reader is not installed. Please upload a CSV file instead.');
            }
        }

        $xlsx = \Shuchkin\SimpleXLSX::parse($filePath);
        if (!$xlsx) {
            $error = \Shuchkin\SimpleXLSX::parseError();
            throw new Exception('Failed to parse Excel file: ' . $error);
        }

        $rawRows = $xlsx->rows();
        $rows = [];

        foreach ($rawRows as $r) {
            $trimmed = array_map(function ($val) {
                return trim((string) $val);
            }, $r);

            // Skip completely empty row
            if (count(array_filter($trimmed, 'strlen')) > 0) {
                $rows[] = $trimmed;
            }
        }

        return $rows;
    }

    /**
     * Helper to find column index in the header row by candidate names
     *
     * @param array $headers
     * @param array $candidates
     * @param int $default
     * @return int
     */
    public static function findColumnIndex(array $headers, array $candidates, int $default = 0): int
    {
        foreach ($headers as $index => $header) {
            $clean = strtolower(trim(str_replace(['_', '-', ' ', '#'], '', (string) $header)));
            foreach ($candidates as $cand) {
                $cleanCand = strtolower(trim(str_replace(['_', '-', ' ', '#'], '', (string) $cand)));
                if ($clean === $cleanCand) {
                    return $index;
                }
            }
        }
        return $default;
    }
}
