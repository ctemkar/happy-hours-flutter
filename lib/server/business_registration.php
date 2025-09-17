<?php
// business_registration.php
header("Content-Type: application/json");

// Database connection
$host = "mysql2-p2.ezhostingserver.com"; 
$user = "sanjay"; 
$pass = "BU@R9gr2971{"; 
$dbname = "interview_helper"; 

$conn = new mysqli($host, $user, $pass, $dbname);
if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "DB connection failed: " . $conn->connect_error]));
}

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
    (happy_hours_id, owner_name, email, Name, description, address, business_category, city, state, country, 
    Open_hours, Happy_hour_start, Happy_hour_end, Happy_hour_yes_no, Telephone, Remark, latitude, longitude, token, verified) 
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");

$stmt->bind_param("sssssssssssssssssssi", 
    $uniqID, $ownerName, $email, $businessName, $description, $address, $category, $city, $state, $country, 
    $openHours, $happyHourStart, $happyHourEnd, $happyHourYesNo, $phone, $remark, $latitude, $longitude, $token, $verified
);

if ($stmt->execute()) {
    // Send verification mail
    $verifyLink = "https://customercallsapp.com/prod/customercallsapp/verify.php?email=" . urlencode($email) . "&token=" . $token;
    $subject = "Verify Your Business Registration";
    $message = "Hi $ownerName,\n\nPlease verify your business registration by clicking:\n$verifyLink\n\nThank you!";
    $headers = "From: no-reply@customercallsapp.com\r\nReply-To: no-reply@customercallsapp.com";

    mail($email, $subject, $message, $headers);

    echo json_encode(["status" => "success", "message" => "Business registered successfully. Verification email sent."]);
} else {
    echo json_encode(["status" => "error", "message" => "DB insert failed: " . $stmt->error]);
}

$stmt->close();
$conn->close();
?>
