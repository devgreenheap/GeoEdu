<?php

namespace App\Http\Controllers;

use App\Models\Categories;
use App\Models\CountryMaster;
use App\Models\Divisions;
use App\Models\GlobalFunction;
use App\Models\StateMaster;
use App\Models\SubCategories;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class CategoryModuleController extends Controller
{
    public function categoryDetails()
    {
        return view('categoryDetails');
    }

    public function categories()
    {
        $categories = Categories::where('status', 1)->orderBy('name')->get();
        return view('categories', compact('categories'));
    }

    public function divisions()
    {
        $categories = Categories::where('status', 1)->orderBy('name')->get();
        return view('divisions', compact('categories'));
    }

    public function listCategories(Request $request)
    {
        $query = Categories::query();
        $totalData = $query->count();

        $limit = $request->input('length');
        $start = $request->input('start');
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('name', 'LIKE', "%{$searchValue}%");
            });
        }

        $totalFiltered = $query->count();

        $result = $query->offset($start)
            ->limit($limit)
            ->orderBy('id', 'DESC')
            ->get();

        $data = $result->map(function ($item) {
            $edit = "<a href='#'
                        rel='{$item->id}'
                        data-name='{$item->name}'
                        class='action-btn edit d-flex align-items-center justify-content-center btn border rounded-2 text-success ms-1'>
                        <i class='uil-pen'></i>
                        </a>";

            $delete = "<a href='#'
                          rel='{$item->id}'
                          class='action-btn delete d-flex align-items-center justify-content-center btn border rounded-2 text-danger ms-1'>
                            <i class='uil-trash-alt'></i>
                        </a>";
            $action = "<span class='d-flex justify-content-end align-items-center'>{$edit}{$delete}</span>";

            $checked = $item->status == 1 ? 'checked' : '';
            $status = "<input type='checkbox' id='categoryStatus-{$item->id}' rel='{$item->id}' class='onOffCategory' {$checked} data-switch='none'/>
                    <label for='categoryStatus-{$item->id}'></label>";

            $createdAt = GlobalFunction::formatDateTime($item->created_at);

            return [
                $item->name,
                $createdAt,
                $status,
                $action,
            ];
        });

        $json_data = [
            "draw" => intval($request->input('draw')),
            "recordsTotal" => intval($totalData),
            "recordsFiltered" => intval($totalFiltered),
            "data" => $data,
        ];

        return response()->json($json_data);
    }

    public function addCategory(Request $request)
    {
        $name = trim((string) ($request->name ?? ''));
        if ($name === '') {
            return GlobalFunction::sendSimpleResponse(false, 'Category name is required');
        }

        $item = new Categories();
        $item->name = $name;
        $item->status = 1;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Category added successfully');
    }

    public function editCategory(Request $request)
    {
        $name = trim((string) ($request->name ?? ''));
        if ($name === '') {
            return GlobalFunction::sendSimpleResponse(false, 'Category name is required');
        }

        $item = Categories::find($request->id);
        $item->name = $name;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Category updated successfully');
    }

    public function deleteCategory(Request $request)
    {
        $item = Categories::find($request->id);
        $item->delete();

        return GlobalFunction::sendSimpleResponse(true, 'Category deleted successfully');
    }

    public function changeCategoryStatus(Request $request)
    {
        $item = Categories::find($request->id);
        $item->status = $request->status;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Status changed successfully!');
    }

    public function listSubCategories(Request $request)
    {
        $query = SubCategories::query();
        $totalData = $query->count();

        $limit = $request->input('length');
        $start = $request->input('start');
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('name', 'LIKE', "%{$searchValue}%");
            });
        }

        $totalFiltered = $query->count();

        $result = $query->with('category:id,name')
            ->offset($start)
            ->limit($limit)
            ->orderBy('id', 'DESC')
            ->get();

        $data = $result->map(function ($item) {
            $edit = "<a href='#'
                        rel='{$item->id}'
                        data-category='{$item->category_id}'
                        data-name='{$item->name}'
                        class='action-btn edit-sub d-flex align-items-center justify-content-center btn border rounded-2 text-success ms-1'>
                        <i class='uil-pen'></i>
                        </a>";

            $delete = "<a href='#'
                          rel='{$item->id}'
                          class='action-btn delete-sub d-flex align-items-center justify-content-center btn border rounded-2 text-danger ms-1'>
                            <i class='uil-trash-alt'></i>
                        </a>";
            $action = "<span class='d-flex justify-content-end align-items-center'>{$edit}{$delete}</span>";

            $checked = $item->status == 1 ? 'checked' : '';
            $status = "<input type='checkbox' id='subCategoryStatus-{$item->id}' rel='{$item->id}' class='onOffSubCategory' {$checked} data-switch='none'/>
                    <label for='subCategoryStatus-{$item->id}'></label>";

            $createdAt = GlobalFunction::formatDateTime($item->created_at);

            return [
                $item->category?->name ?? '-',
                $item->name,
                $createdAt,
                $status,
                $action,
            ];
        });

        $json_data = [
            "draw" => intval($request->input('draw')),
            "recordsTotal" => intval($totalData),
            "recordsFiltered" => intval($totalFiltered),
            "data" => $data,
        ];

        return response()->json($json_data);
    }

    public function addSubCategory(Request $request)
    {
        $name = trim((string) ($request->name ?? ''));
        if ($name === '') {
            return GlobalFunction::sendSimpleResponse(false, 'Sub category name is required');
        }

        $item = new SubCategories();
        $item->category_id = $request->category_id;
        $item->name = $name;
        $item->status = 1;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Sub category added successfully');
    }

    public function editSubCategory(Request $request)
    {
        $name = trim((string) ($request->name ?? ''));
        if ($name === '') {
            return GlobalFunction::sendSimpleResponse(false, 'Sub category name is required');
        }

        $item = SubCategories::find($request->id);
        $item->category_id = $request->category_id;
        $item->name = $name;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Sub category updated successfully');
    }

    public function deleteSubCategory(Request $request)
    {
        $item = SubCategories::find($request->id);
        $item->delete();

        return GlobalFunction::sendSimpleResponse(true, 'Sub category deleted successfully');
    }

    public function changeSubCategoryStatus(Request $request)
    {
        $item = SubCategories::find($request->id);
        $item->status = $request->status;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Status changed successfully!');
    }

    // Divisions

    public function listDivisionsBySubCategory(Request $request)
    {
        $divisions = Divisions::where('sub_category_id', $request->sub_category_id)
            ->where('status', 1)
            ->orderBy('name')
            ->get(['id', 'name']);

        return response()->json([
            'status' => true,
            'data' => $divisions,
        ]);
    }

    public function listDivisions(Request $request)
    {
        $query = Divisions::query();
        $totalData = $query->count();

        $limit = $request->input('length');
        $start = $request->input('start');
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('name', 'LIKE', "%{$searchValue}%");
            });
        }

        $totalFiltered = $query->count();

        $result = $query->with('category:id,name', 'subCategory:id,name')
            ->offset($start)
            ->limit($limit)
            ->orderBy('id', 'DESC')
            ->get();

        $data = $result->map(function ($item) {
            $edit = "<a href='#'
                        rel='{$item->id}'
                        data-category='{$item->category_id}'
                        data-sub-category='{$item->sub_category_id}'
                        data-name='{$item->name}'
                        class='action-btn edit-division d-flex align-items-center justify-content-center btn border rounded-2 text-success ms-1'>
                        <i class='uil-pen'></i>
                        </a>";

            $delete = "<a href='#'
                          rel='{$item->id}'
                          class='action-btn delete-division d-flex align-items-center justify-content-center btn border rounded-2 text-danger ms-1'>
                            <i class='uil-trash-alt'></i>
                        </a>";
            $action = "<span class='d-flex justify-content-end align-items-center'>{$edit}{$delete}</span>";

            $checked = $item->status == 1 ? 'checked' : '';
            $status = "<input type='checkbox' id='divisionStatus-{$item->id}' rel='{$item->id}' class='onOffDivision' {$checked} data-switch='none'/>
                    <label for='divisionStatus-{$item->id}'></label>";

            $createdAt = GlobalFunction::formatDateTime($item->created_at);

            return [
                $item->category?->name ?? '-',
                $item->subCategory?->name ?? '-',
                $item->name,
                $createdAt,
                $status,
                $action,
            ];
        });

        $json_data = [
            "draw" => intval($request->input('draw')),
            "recordsTotal" => intval($totalData),
            "recordsFiltered" => intval($totalFiltered),
            "data" => $data,
        ];

        return response()->json($json_data);
    }

    public function addDivision(Request $request)
    {
        $name = trim((string) ($request->name ?? ''));
        if ($name === '') {
            return GlobalFunction::sendSimpleResponse(false, 'Division name is required');
        }

        $item = new Divisions();
        $item->category_id = $request->category_id;
        $item->sub_category_id = $request->sub_category_id;
        $item->name = $name;
        $item->status = 1;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Division added successfully');
    }

    public function editDivision(Request $request)
    {
        $name = trim((string) ($request->name ?? ''));
        if ($name === '') {
            return GlobalFunction::sendSimpleResponse(false, 'Division name is required');
        }

        $item = Divisions::find($request->id);
        $item->category_id = $request->category_id;
        $item->sub_category_id = $request->sub_category_id;
        $item->name = $name;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Division updated successfully');
    }

    public function deleteDivision(Request $request)
    {
        $item = Divisions::find($request->id);
        $item->delete();

        return GlobalFunction::sendSimpleResponse(true, 'Division deleted successfully');
    }

    public function changeDivisionStatus(Request $request)
    {
        $item = Divisions::find($request->id);
        $item->status = $request->status;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Status changed successfully!');
    }

    public function countries()
    {
        return view('countries');
    }

    public function listCountries(Request $request)
    {
        $query = CountryMaster::query();
        $totalData = $query->count();

        $limit = intval($request->input('length') ?? 10);
        $start = intval($request->input('start') ?? 0);
        $searchValue = trim((string) $request->input('search.value'));

        if ($searchValue !== '') {
            $query->where('name', 'LIKE', "%{$searchValue}%");
        }

        $totalFiltered = $query->count();

        $rows = $query->offset($start)
            ->limit($limit)
            ->orderBy('id', 'DESC')
            ->get();

        $data = $rows->map(function ($item) {
            $edit = "<a href='#'
                        rel='{$item->id}'
                        data-name='" . e($item->name) . "'
                        class='action-btn edit-country d-flex align-items-center justify-content-center btn border rounded-2 text-success ms-1'>
                        <i class='uil-pen'></i>
                    </a>";
            $delete = "<a href='#'
                        rel='{$item->id}'
                        class='action-btn delete-country d-flex align-items-center justify-content-center btn border rounded-2 text-danger ms-1'>
                        <i class='uil-trash-alt'></i>
                    </a>";
            $action = "<span class='d-flex justify-content-end align-items-center'>{$edit}{$delete}</span>";

            return [
                e($item->name),
                $action,
            ];
        });

        return response()->json([
            'draw' => intval($request->input('draw')),
            'recordsTotal' => intval($totalData),
            'recordsFiltered' => intval($totalFiltered),
            'data' => $data,
        ]);
    }

    public function addCountry(Request $request)
    {
        $name = trim((string) ($request->name ?? ''));
        if ($name === '') {
            return GlobalFunction::sendSimpleResponse(false, 'Country name is required');
        }

        if (CountryMaster::whereRaw('LOWER(name) = ?', [strtolower($name)])->exists()) {
            return GlobalFunction::sendSimpleResponse(false, 'Country already exists');
        }

        $item = new CountryMaster();
        $item->name = $name;
        $item->status = 1;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Country added successfully');
    }

    public function editCountry(Request $request)
    {
        $name = trim((string) ($request->name ?? ''));
        if ($name === '') {
            return GlobalFunction::sendSimpleResponse(false, 'Country name is required');
        }

        $item = CountryMaster::find($request->id);
        if (!$item) {
            return GlobalFunction::sendSimpleResponse(false, 'Country not found');
        }

        $exists = CountryMaster::whereRaw('LOWER(name) = ?', [strtolower($name)])
            ->where('id', '!=', $item->id)
            ->exists();
        if ($exists) {
            return GlobalFunction::sendSimpleResponse(false, 'Country already exists');
        }

        $item->name = $name;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Country updated successfully');
    }

    public function deleteCountry(Request $request)
    {
        $item = CountryMaster::find($request->id);
        if (!$item) {
            return GlobalFunction::sendSimpleResponse(false, 'Country not found');
        }

        $hasStates = StateMaster::where('country_id', $item->id)->exists();
        if ($hasStates) {
            return GlobalFunction::sendSimpleResponse(false, 'Cannot delete country with existing states');
        }

        $item->delete();
        return GlobalFunction::sendSimpleResponse(true, 'Country deleted successfully');
    }

    public function statesMaster()
    {
        $countries = CountryMaster::orderBy('name')->get(['id', 'name']);
        return view('statesMaster', compact('countries'));
    }

    public function listStatesMaster(Request $request)
    {
        $query = StateMaster::query()->with('country:id,name');
        $totalData = $query->count();

        $limit = intval($request->input('length') ?? 10);
        $start = intval($request->input('start') ?? 0);
        $searchValue = trim((string) $request->input('search.value'));

        if ($searchValue !== '') {
            $query->where(function ($q) use ($searchValue) {
                $q->where('name', 'LIKE', "%{$searchValue}%")
                    ->orWhereHas('country', function ($countryQuery) use ($searchValue) {
                        $countryQuery->where('name', 'LIKE', "%{$searchValue}%");
                    });
            });
        }

        $totalFiltered = $query->count();

        $rows = $query->offset($start)
            ->limit($limit)
            ->orderBy('id', 'DESC')
            ->get();

        $data = $rows->map(function ($item) {
            $edit = "<a href='#'
                        rel='{$item->id}'
                        data-country-id='{$item->country_id}'
                        data-name='" . e($item->name) . "'
                        class='action-btn edit-state d-flex align-items-center justify-content-center btn border rounded-2 text-success ms-1'>
                        <i class='uil-pen'></i>
                    </a>";
            $delete = "<a href='#'
                        rel='{$item->id}'
                        class='action-btn delete-state d-flex align-items-center justify-content-center btn border rounded-2 text-danger ms-1'>
                        <i class='uil-trash-alt'></i>
                    </a>";
            $action = "<span class='d-flex justify-content-end align-items-center'>{$edit}{$delete}</span>";

            return [
                e($item->country?->name ?? '-'),
                e($item->name),
                $action,
            ];
        });

        return response()->json([
            'draw' => intval($request->input('draw')),
            'recordsTotal' => intval($totalData),
            'recordsFiltered' => intval($totalFiltered),
            'data' => $data,
        ]);
    }

    public function addStateMaster(Request $request)
    {
        $countryId = intval($request->country_id ?? 0);
        $name = trim((string) ($request->name ?? ''));

        if ($countryId <= 0 || !CountryMaster::where('id', $countryId)->exists()) {
            return GlobalFunction::sendSimpleResponse(false, 'Valid country is required');
        }
        if ($name === '') {
            return GlobalFunction::sendSimpleResponse(false, 'State name is required');
        }

        $exists = StateMaster::where('country_id', $countryId)
            ->whereRaw('LOWER(name) = ?', [strtolower($name)])
            ->exists();
        if ($exists) {
            return GlobalFunction::sendSimpleResponse(false, 'State already exists for selected country');
        }

        $item = new StateMaster();
        $item->country_id = $countryId;
        $item->name = $name;
        $item->status = 1;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'State added successfully');
    }

    public function editStateMaster(Request $request)
    {
        $item = StateMaster::find($request->id);
        if (!$item) {
            return GlobalFunction::sendSimpleResponse(false, 'State not found');
        }

        $countryId = intval($request->country_id ?? 0);
        $name = trim((string) ($request->name ?? ''));

        if ($countryId <= 0 || !CountryMaster::where('id', $countryId)->exists()) {
            return GlobalFunction::sendSimpleResponse(false, 'Valid country is required');
        }
        if ($name === '') {
            return GlobalFunction::sendSimpleResponse(false, 'State name is required');
        }

        $exists = StateMaster::where('country_id', $countryId)
            ->whereRaw('LOWER(name) = ?', [strtolower($name)])
            ->where('id', '!=', $item->id)
            ->exists();
        if ($exists) {
            return GlobalFunction::sendSimpleResponse(false, 'State already exists for selected country');
        }

        $item->country_id = $countryId;
        $item->name = $name;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'State updated successfully');
    }

    public function deleteStateMaster(Request $request)
    {
        $item = StateMaster::find($request->id);
        if (!$item) {
            return GlobalFunction::sendSimpleResponse(false, 'State not found');
        }

        $item->delete();
        return GlobalFunction::sendSimpleResponse(true, 'State deleted successfully');
    }
}
