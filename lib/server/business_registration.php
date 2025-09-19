<?php
// business_registration.php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: Application/json"); 

// Simple logger function
function logMessage($message) {
    $logFile = __DIR__ . "/debug_log.txt";
    file_put_contents($logFile, date("Y-m-d H:i:s") . " | " . $message . "\n", FILE_APPEND);
}

// Database connection
$host = "mysql2-p2.ezhostingserver.com"; 
$user = "sanjay"; 
$pass = "BU@R9gr2971{"; 
$dbname = "interview_helper"; 

$conn = new mysqli($host, $user, $pass, $dbname);
if ($conn->connect_error) {
    logMessage("DB connection failed: " . $conn->connect_error);
    die(json_encode(["status" => "error", "message" => "DB connection failed."]));
}

// Log incoming POST
logMessage("POST data: " . json_encode($_POST));

// Get POST data
$businessName   = $_POST['businessName'] ?? '';
$ownerName      = $_POST['ownerName'] ?? '';
$email          = $_POST['email'] ?? '';
$phone          = $_POST['phone'] ?? '';
$address        = $_POST['address'] ?? '';
$city           = $_POST['city'] ?? '';
$state          = $_POST['state'] ?? '';
$country        = $_POST['country'] ?? '';
$pin            = $_POST['pin'] ?? '';
$category       = $_POST['category'] ?? '';
$description    = $_POST['description'] ?? '';
$openHours      = $_POST['open_hours'] ?? '';
$happyHourStart = $_POST['happy_hour_start'] ?? '';
$happyHourEnd   = $_POST['happy_hour_end'] ?? '';
$happyHourYesNo = $_POST['happy_hour_yes_no'] ?? 'No';
$remark         = $_POST['remark'] ?? '';
$latitude       = $_POST['latitude'] ?? '';
$longitude      = $_POST['longitude'] ?? '';

$token    = bin2hex(random_bytes(16));
$verified = 0;
$uniqID   = bin2hex(random_bytes(8));

// Insert into DB
$stmt = $conn->prepare("INSERT INTO happy_hours_global_test
    (happy_hours_id, owner_name, email, Name, Description, Address, business_category, city, country, Open_hours, 
    Happy_hour_start, Happy_hour_end, Happy_hours_yes_no, Telephone, Remark, latitude, longitude, token, verified) 
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");

if (!$stmt) {
    logMessage("Prepare failed: " . $conn->error);
    echo json_encode(["status" => "error", "message" => "DB prepare failed"]);
    exit;
}

$stmt->bind_param("ssssssssssssssssssi", 
    $uniqID, $ownerName, $email, $businessName, $description, $address, $category, $city, $country, 
    $openHours, $happyHourStart, $happyHourEnd, $happyHourYesNo, $phone, $remark, $latitude, $longitude, $token, $verified
);

if ($stmt->execute()) {
    logMessage("Insert successful for email: $email");

    // Send verification mail
    $verifyLink = "https://customercallsapp.com/prod/customercallsapp/verify.php?email=" . urlencode($email) . "&token=" . $token;
    $subject = "Verify Your Business Registration";
    $message = "Hi $ownerName,\n\nPlease verify your business registration by clicking:\n$verifyLink\n\nThank you!";
    $headers = "From: no-reply@customercallsapp.com\r\nReply-To: no-reply@customercallsapp.com";

    if (mail($email, $subject, $message, $headers)) {
        logMessage("Mail sent to $email");
    } else {
        logMessage("Mail failed to $email");
    }

    echo json_encode(["status" => "success", "message" => "Business registered successfully. Verification email sent."]);
} else {
    logMessage("DB insert failed: " . $stmt->error);
    echo json_encode(["status" => "error", "message" => "DB insert failed."]);
}

$stmt->close();
$conn->close();
?>
