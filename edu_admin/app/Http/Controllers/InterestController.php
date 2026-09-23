<?php

namespace App\Http\Controllers;

use App\Models\GlobalFunction;
use App\Models\Interest;
use Illuminate\Http\Request;

class InterestController extends Controller
{
    public function interests()
    {
        $interests = Interest::where('status', 1)->orderBy('name')->get();
        return view('interests', compact('interests'));
    }

    public function listInterests(Request $request)
    {
        $query = Interest::query();
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
            $status = "<input type='checkbox' id='interestStatus-{$item->id}' rel='{$item->id}' class='onOffInterest' {$checked} data-switch='none'/>
                    <label for='interestStatus-{$item->id}'></label>";

            return [
                $item->name,
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

    public function addInterest(Request $request)
    {
        $name = trim((string) ($request->name ?? ''));
        if ($name === '') {
            return GlobalFunction::sendSimpleResponse(false, 'Interest name is required');
        }

        $item = new Interest();
        $item->name = $name;
        $item->status = 1;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Interest added successfully');
    }

    public function editInterest(Request $request)
    {
        $name = trim((string) ($request->name ?? ''));
        if ($name === '') {
            return GlobalFunction::sendSimpleResponse(false, 'Interest name is required');
        }

        $item = Interest::find($request->id);
        $item->name = $name;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Interest updated successfully');
    }

    public function deleteInterest(Request $request)
    {
        $item = Interest::find($request->id);
        $item->delete();

        return GlobalFunction::sendSimpleResponse(true, 'Interest deleted successfully');
    }

    public function changeInterestStatus(Request $request)
    {
        $item = Interest::find($request->id);
        $item->status = $request->status;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Status changed successfully!');
    }
}
