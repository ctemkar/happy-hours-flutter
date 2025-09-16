<?php
// verify.php

$host = "mysql2-p2.ezhostingserver.com"; 
$user = "sanjay"; 
$pass = "BU@R9gr2971{"; 
$dbname = "interview_helper"; 

$conn = new mysqli($host, $user, $pass, $dbname);

if ($conn->connect_error) {
    die("Database connection failed: " . $conn->connect_error);
}

$email = $_GET['email'] ?? '';
$token = $_GET['token'] ?? '';

if (!empty($email) && !empty($token)) {
    $stmt = $conn->prepare("SELECT * FROM happy_hours_global_test WHERE email=? AND token=? AND verified=0 LIMIT 1");
    $stmt->bind_param("ss", $email, $token);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $update = $conn->prepare("UPDATE happy_hours_global_test SET verified=1 WHERE email=? AND token=?");
        $update->bind_param("ss", $email, $token);
        $update->execute();
        echo "Your business has been successfully verified!";
    } else {
        echo "Invalid or already verified link.";
    }
} else {
    echo "Invalid request.";
}

$conn->close();
?>
