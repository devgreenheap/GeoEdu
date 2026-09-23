<?php

namespace App\Http\Controllers;

use App\Models\Categories;
use App\Models\GlobalFunction;
use App\Models\SubCategories;
use App\Models\Topics;
use Illuminate\Http\Request;

class TopicController extends Controller
{
    public function topics()
    {
        $categories = Categories::where('status', 1)->orderBy('name')->get();
        return view('topics', compact('categories'));
    }

    public function listSubCategoriesByCategory(Request $request)
    {
        $subCategories = SubCategories::where('category_id', $request->category_id)
            ->where('status', 1)
            ->orderBy('name')
            ->get(['id', 'name']);

        return response()->json([
            'status' => true,
            'data' => $subCategories,
        ]);
    }

    public function listTopics(Request $request)
    {
        $query = Topics::query();
        $totalData = $query->count();

        $limit = $request->input('length');
        $start = $request->input('start');
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('name', 'LIKE', "%{$searchValue}%")
                    ->orWhereHas('category', function ($categoryQuery) use ($searchValue) {
                        $categoryQuery->where('name', 'LIKE', "%{$searchValue}%");
                    })
                    ->orWhereHas('subCategory', function ($subCategoryQuery) use ($searchValue) {
                        $subCategoryQuery->where('name', 'LIKE', "%{$searchValue}%");
                    });
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
            $status = "<input type='checkbox' id='topicStatus-{$item->id}' rel='{$item->id}' class='onOffTopic' {$checked} data-switch='none'/>
                    <label for='topicStatus-{$item->id}'></label>";

            return [
                $item->category?->name ?? '-',
                $item->subCategory?->name ?? '-',
                $item->name,
                $status,
                $action,
            ];
        });

        $json_data = [
            'draw' => intval($request->input('draw')),
            'recordsTotal' => intval($totalData),
            'recordsFiltered' => intval($totalFiltered),
            'data' => $data,
        ];

        return response()->json($json_data);
    }

    public function addTopic(Request $request)
    {
        $item = new Topics();
        $item->category_id = $request->category_id;
        $item->sub_category_id = $request->sub_category_id;
        $item->name = $request->name;
        $item->status = 1;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Topic added successfully');
    }

    public function editTopic(Request $request)
    {
        $item = Topics::find($request->id);
        $item->category_id = $request->category_id;
        $item->sub_category_id = $request->sub_category_id;
        $item->name = $request->name;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Topic updated successfully');
    }

    public function deleteTopic(Request $request)
    {
        $item = Topics::find($request->id);
        $item->delete();

        return GlobalFunction::sendSimpleResponse(true, 'Topic deleted successfully');
    }

    public function changeTopicStatus(Request $request)
    {
        $item = Topics::find($request->id);
        $item->status = $request->status;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Status changed successfully!');
    }
}
