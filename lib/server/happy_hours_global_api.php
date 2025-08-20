<?php
// happy_hours_api.php
// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    header("Access-Control-Allow-Origin: *");
    header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
    header("Access-Control-Allow-Headers: Content-Type");
    http_response_code(200);
    exit();
}

error_reporting(E_ALL);
ini_set('display_errors', 1); // set to 1 for debugging on dev only
ini_set('log_errors', 1);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

set_time_limit(60);

// ---- Config ----
$host     = "mysql2-p2.ezhostingserver.com";
$username = "sanjay";
$password = "BU@R9gr2971{";
$database = "interview_helper";

// Connect
$conn = new mysqli('p:' . $host, $username, $password, $database);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["error" => "Database connection failed"]);
    exit;
}

// Get params
$city     = isset($_GET['city']) ? trim($_GET['city']) : 'ALL';
$business = isset($_GET['business']) ? trim($_GET['business']) : 'ALL';

// Function to get data for a city + business
function getHappyHours($conn, $city, $business) {
    $sql = "SELECT happy_hours_id, Name, Address, Google_Marker, image_link, Open_hours, 
                   Happy_hour_start, Happy_hour_end, Telephone, latitude, longitude, city, Business_category
            FROM happy_hours_bangkok
            WHERE TRIM(COALESCE(Open_hours, '')) NOT IN ('', 'false')
              AND TRIM(COALESCE(Happy_hour_start, '')) NOT IN ('', 'false')
              AND TRIM(COALESCE(Happy_hour_end, '')) NOT IN ('', 'false')";

    $params = [];
    $types  = "";

    // Apply filters
    if (strtoupper($city) !== "ALL") {
        $sql .= " AND city = ?";
        $params[] = $city;
        $types .= "s";
    }

    if (strtoupper($business) !== "ALL") {
        $sql .= " AND Business_category = ?";
        $params[] = $business;
        $types .= "s";
    }

    $stmt = $conn->prepare($sql);
    if (!empty($params)) {
        $stmt->bind_param($types, ...$params);
    }

    $stmt->execute();
    return $stmt->get_result();
}

// Fetch results
$result = getHappyHours($conn, $city, $business);

// Fetch all rows
$data = [];
while ($row = $result->fetch_assoc()) {
    foreach ($row as $key => $value) {
        if ($value === null || $value === false) {
            $row[$key] = "";
        } elseif (!mb_check_encoding($value, 'UTF-8')) {
            $row[$key] = mb_convert_encoding($value, 'UTF-8', 'ISO-8859-1');
        }
    }
    $data[] = $row;
}

echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

if (json_last_error() !== JSON_ERROR_NONE) {
    error_log("JSON Error: " . json_last_error_msg());
}

$conn->close();
?>
