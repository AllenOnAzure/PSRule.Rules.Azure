<#
.SYNOPSIS
    Azure CAF PSRule Analysis and Reporting Tool with HTML report

.DESCRIPTION
    This script analyzes Azure Cloud Adoption Framework (CAF) JSON files using PSRule 
    validation rules and creates an interactive HTML report. The report includes 
    search/filter capabilities and shows which Azure resources pass or fail 
    recommended practices.
#>

# Run your analysis
Assert-PSRule -Module "PSRule.Rules.Azure" -InputPath "C:\caf-analysis\" -Format Json -OutputPath "C:\caf-analysis\results.csv" -OutputFormat Csv

# Create an enhanced HTML report with filtering
$results = Import-Csv "C:\caf-analysis\results.csv"

$html = @"
<!DOCTYPE html>
<html>
<head>
    <style>
        body { 
            font-family: 'Segoe UI', Arial, sans-serif; 
            margin: 20px; 
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 { 
            color: #333;
            margin-bottom: 20px;
            border-bottom: 2px solid #eee;
            padding-bottom: 10px;
        }
        .summary { 
            background: #f8f9fa; 
            padding: 15px; 
            border-radius: 6px; 
            margin-bottom: 20px;
            display: flex;
            gap: 30px;
        }
        .summary-box {
            padding: 10px 20px;
            border-radius: 4px;
            font-size: 16px;
        }
        .summary-box.pass { background: #d4edda; }
        .summary-box.fail { background: #f8d7da; }
        .summary-box.total { background: #e2e3e5; }
        .filter-section {
            background: #fff;
            padding: 20px;
            border-radius: 6px;
            margin-bottom: 20px;
            border: 1px solid #ddd;
        }
        .filter-row {
            display: flex;
            gap: 20px;
            margin-bottom: 15px;
            flex-wrap: wrap;
        }
        .filter-group {
            flex: 1;
            min-width: 200px;
        }
        .filter-group label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
            color: #555;
        }
        .filter-group input, .filter-group select {
            width: 100%;
            padding: 8px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 14px;
        }
        .filter-group input:focus, .filter-group select:focus {
            outline: none;
            border-color: #007bff;
            box-shadow: 0 0 5px rgba(0,123,255,0.3);
        }
        .outcome-filters {
            display: flex;
            gap: 15px;
            align-items: center;
            padding: 10px 0;
        }
        .outcome-filters label {
            display: flex;
            align-items: center;
            gap: 5px;
            cursor: pointer;
        }
        .outcome-filters input[type="checkbox"] {
            width: auto;
            margin-right: 5px;
        }
        .filter-buttons {
            display: flex;
            gap: 10px;
            margin-top: 10px;
        }
        .btn {
            padding: 8px 16px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            transition: background-color 0.2s;
        }
        .btn-primary {
            background-color: #007bff;
            color: white;
        }
        .btn-primary:hover {
            background-color: #0056b3;
        }
        .btn-secondary {
            background-color: #6c757d;
            color: white;
        }
        .btn-secondary:hover {
            background-color: #545b62;
        }
        table { 
            border-collapse: collapse; 
            width: 100%; 
            margin-top: 20px;
            background-color: white;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        th { 
            background: #343a40; 
            color: white; 
            padding: 12px 8px; 
            font-weight: 600;
            text-align: left;
            position: sticky;
            top: 0;
        }
        td { 
            padding: 10px 8px; 
            border: 1px solid #dee2e6; 
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .Pass { 
            background: #d4edda !important; 
            color: #155724; 
            font-weight: 600;
        }
        .Fail { 
            background: #f8d7da !important; 
            color: #721c24; 
            font-weight: 600;
        }
        .rule-name {
            font-family: 'Courier New', monospace;
            font-size: 13px;
        }
        .stats {
            display: flex;
            gap: 10px;
            margin-top: 10px;
            color: #666;
        }
        .badge {
            padding: 3px 8px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: normal;
        }
        .badge-pass { background: #d4edda; color: #155724; }
        .badge-fail { background: #f8d7da; color: #721c24; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔍 PSRule Analysis Results</h1>
        
        <div class="summary">
            <div class="summary-box total">
                <strong>Total Rules Evaluated:</strong> $($results.Count)
            </div>
            <div class="summary-box pass">
                <strong>✅ Pass:</strong> $($results | Where-Object { $_.Outcome -eq 'Pass' } | Measure-Object | Select-Object -ExpandProperty Count)
            </div>
            <div class="summary-box fail">
                <strong>❌ Fail:</strong> $($results | Where-Object { $_.Outcome -eq 'Fail' } | Measure-Object | Select-Object -ExpandProperty Count)
            </div>
        </div>

        <div class="filter-section">
            <h3>Filter Results</h3>
            <div class="filter-row">
                <div class="filter-group">
                    <label>🔎 Search all fields:</label>
                    <input type="text" id="searchBox" placeholder="Type to search..." onkeyup="filterTable()">
                </div>
                <div class="filter-group">
                    <label>📋 Rule Name:</label>
                    <input type="text" id="ruleFilter" placeholder="Filter by rule..." onkeyup="filterTable()">
                </div>
                <div class="filter-group">
                    <label>🎯 Target:</label>
                    <input type="text" id="targetFilter" placeholder="Filter by target..." onkeyup="filterTable()">
                </div>
            </div>
            
            <div class="outcome-filters">
                <label>
                    <input type="checkbox" id="showPass" checked onchange="filterTable()"> Show Pass <span class="badge badge-pass">$($results | Where-Object { $_.Outcome -eq 'Pass' } | Measure-Object | Select-Object -ExpandProperty Count)</span>
                </label>
                <label>
                    <input type="checkbox" id="showFail" checked onchange="filterTable()"> Show Fail <span class="badge badge-fail">$($results | Where-Object { $_.Outcome -eq 'Fail' } | Measure-Object | Select-Object -ExpandProperty Count)</span>
                </label>
            </div>
            
            <div class="filter-buttons">
                <button class="btn btn-primary" onclick="filterTable()">Apply Filters</button>
                <button class="btn btn-secondary" onclick="resetFilters()">Reset All</button>
            </div>
            
            <div class="stats" id="filterStats">
                Showing <span id="visibleCount">$($results.Count)</span> of <span id="totalCount">$($results.Count)</span> results
            </div>
        </div>

        <table id="resultsTable">
            <thead>
                <tr>
                    <th onclick="sortTable(0)">Rule Name ⬍</th>
                    <th onclick="sortTable(1)">Target ⬍</th>
                    <th onclick="sortTable(2)">Outcome ⬍</th>
                    <th>Synopsis</th>
                    <th>Recommendation</th>
                </tr>
            </thead>
            <tbody>
"@

foreach ($row in $results) {
    $escapedSynopsis = $row.Synopsis -replace '"', '&quot;' -replace "'", "&apos;"
    $escapedRecommendation = $row.Recommendation -replace '"', '&quot;' -replace "'", "&apos;"
    $escapedTarget = $row.TargetName -replace '"', '&quot;' -replace "'", "&apos;"
    $escapedRule = $row.RuleName -replace '"', '&quot;' -replace "'", "&apos;"
    
    $html += @"
                <tr data-rule="$escapedRule" data-target="$escapedTarget" data-outcome="$($row.Outcome)">
                    <td class="rule-name">$($row.RuleName)</td>
                    <td>$($row.TargetName)</td>
                    <td class="$($row.Outcome)">$($row.Outcome)</td>
                    <td>$($row.Synopsis)</td>
                    <td>$($row.Recommendation)</td>
                </tr>
"@
}

$html += @"
            </tbody>
        </table>
    </div>

    <script>
        function filterTable() {
            const searchTerm = document.getElementById('searchBox').value.toLowerCase();
            const ruleFilter = document.getElementById('ruleFilter').value.toLowerCase();
            const targetFilter = document.getElementById('targetFilter').value.toLowerCase();
            const showPass = document.getElementById('showPass').checked;
            const showFail = document.getElementById('showFail').checked;
            
            const rows = document.querySelectorAll('#resultsTable tbody tr');
            let visibleCount = 0;
            
            rows.forEach(row => {
                const ruleName = row.getAttribute('data-rule').toLowerCase();
                const target = row.getAttribute('data-target').toLowerCase();
                const outcome = row.getAttribute('data-outcome');
                const text = row.textContent.toLowerCase();
                
                // Check all filter conditions
                const matchesSearch = searchTerm === '' || text.includes(searchTerm);
                const matchesRule = ruleFilter === '' || ruleName.includes(ruleFilter);
                const matchesTarget = targetFilter === '' || target.includes(targetFilter);
                const matchesOutcome = (outcome === 'Pass' && showPass) || (outcome === 'Fail' && showFail);
                
                if (matchesSearch && matchesRule && matchesTarget && matchesOutcome) {
                    row.style.display = '';
                    visibleCount++;
                } else {
                    row.style.display = 'none';
                }
            });
            
            // Update statistics
            document.getElementById('visibleCount').textContent = visibleCount;
            document.getElementById('filterStats').innerHTML = 
                'Showing <strong>' + visibleCount + '</strong> of <strong>' + rows.length + '</strong> results';
        }
        
        function resetFilters() {
            document.getElementById('searchBox').value = '';
            document.getElementById('ruleFilter').value = '';
            document.getElementById('targetFilter').value = '';
            document.getElementById('showPass').checked = true;
            document.getElementById('showFail').checked = true;
            filterTable();
        }
        
        function sortTable(columnIndex) {
            const table = document.getElementById('resultsTable');
            const tbody = table.tBodies[0];
            const rows = Array.from(tbody.rows);
            const isAscending = table.dataset.sortOrder !== 'asc';
            
            rows.sort((a, b) => {
                const aText = a.cells[columnIndex].textContent.trim();
                const bText = b.cells[columnIndex].textContent.trim();
                
                if (columnIndex === 2) { // Outcome column - custom sort order (Pass then Fail)
                    const order = { 'Pass': 0, 'Fail': 1 };
                    return isAscending ? order[aText] - order[bText] : order[bText] - order[aText];
                }
                
                return isAscending ? aText.localeCompare(bText) : bText.localeCompare(aText);
            });
            
            // Clear and re-append sorted rows
            while (tbody.firstChild) {
                tbody.removeChild(tbody.firstChild);
            }
            rows.forEach(row => tbody.appendChild(row));
            
            table.dataset.sortOrder = isAscending ? 'asc' : 'desc';
        }
        
        // Initialize filter on page load
        document.addEventListener('DOMContentLoaded', filterTable);
    </script>
</body>
</html>
"@

$html | Out-File -FilePath "C:\caf-analysis\results.html" -Encoding UTF8

Write-Host "✨ Enhanced HTML report created at: C:\caf-analysis\results.html" -ForegroundColor Green
