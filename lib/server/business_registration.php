<?php
// business_registration.php

// Database connection
$host = "mysql2-p2.ezhostingserver.com"; 
$user = "sanjay"; 
$pass = "BU@R9gr2971{"; 
$dbname = "interview_helper"; 

$conn = new mysqli($host, $user, $pass, $dbname);

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Database connection failed: " . $conn->connect_error]));
}

// Get form fields from POST
$businessName       = $_POST['businessName'] ?? '';
$ownerName          = $_POST['ownerName'] ?? '';
$email              = $_POST['email'] ?? '';
$phone              = $_POST['phone'] ?? '';
$address            = $_POST['address'] ?? '';
$city               = $_POST['city'] ?? '';
$state              = $_POST['state'] ?? '';
$country            = $_POST['country'] ?? '';
$pin                = $_POST['pin'] ?? '';
$category           = $_POST['category'] ?? '';
$description        = $_POST['description'] ?? '';
$openHours          = $_POST['open_hours'] ?? '';
$happyHourStart     = $_POST['happy_hour_start'] ?? '';
$happyHourEnd       = $_POST['happy_hour_end'] ?? '';
$happyHourYesNo     = $_POST['happy_hour_yes_no'] ?? 'No';
$remark             = $_POST['remark'] ?? '';
$latitude           = $_POST['latitude'] ?? '';
$longitude          = $_POST['longitude'] ?? '';
$token              = bin2hex(random_bytes(16)); // unique token
$verified           = 0; // default not verified

// Upload folder
$uploadDir = "upload/"; 
if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0777, true);
}

$imageLink = "";
$baseUrl = "https://customercallsapp.com/prod/customercallsapp/business_images/"; // <-- replace with your domain

// Handle image upload
if (isset($_FILES['photo']) && $_FILES['photo']['error'] === UPLOAD_ERR_OK) {
    $fileName = time() . "_" . basename($_FILES['photo']['name']);
    $filePath = $uploadDir . $fileName;

    if (move_uploaded_file($_FILES['photo']['tmp_name'], $filePath)) {
        $imageLink = $baseUrl . $fileName;
    }
}

$UniqID = UUID();

// Insert into DB
$stmt = $conn->prepare("INSERT INTO happy_hours_global_test
    (happy_hours_id, owner_name, email, Name, description, address, business_category, city,  country, image_link,   
    Open_hours, Happy_hour_start, Happy_hour_end, Happy_hour_yes_no, Telephone, Remark, latitude, longitude,  token, verified) 
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");

$stmt->bind_param("sssssssssssssssssssi", 
    $UniqID, $ownerName, $email, $businessName, $description, $address, $category,  $city,  
    $country, $imageLink,, $openHours, $happyHourStart, $happyHourEnd, $happyHourYesNo, $phone,
    $remark, $latitude, $longitude,  $token, $verified
);

if ($stmt->execute()) {
    // Create verification link
    $verifyLink = "https://customercallsapp.com/prod/customercallsapp/verify.php?email=" . urlencode($email) . "&token=" . $token;

    // Send email
    $subject = "Verify Your Business Registration";
    $message = "Hi $ownerName,\n\nPlease verify your business registration for Happy Hours by clicking the link below:\n\n$verifyLink\n\nThank you!";
    $headers = "From: no-reply@customercallsapp.com\r\nReply-To: no-reply@customercallsapp.com";

    mail($email, $subject, $message, $headers);

    echo json_encode([
        "status" => "success",
        "message" => "Business registered successfully. Please check your email for verification."
    ]);
} else {
    echo json_encode(["status" => "error", "message" => "Failed to register business: " . $stmt->error]);
}

$stmt->close();
$conn->close();
?>
