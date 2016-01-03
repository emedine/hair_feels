<?php
$thedata = $_GET['tweet'];
$fields = "text='".$thedata."'";
$ch = curl_init();

curl_setopt($ch, CURLOPT_URL,"http://text-processing.com/api/sentiment/");
curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS,$fields);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec ($ch);

curl_close ($ch);

echo "$response\n";      

?>