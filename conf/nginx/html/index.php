<?php

$apikey_file = '/data/common/prj-honeypot-api.key';

if(file_exists($apikey_file)){
  $file_array = file($apikey_file, FILE_SKIP_EMPTY_LINES | FILE_IGNORE_NEW_LINES);
  $key = $file_array[0];
/* OLD METHOD
  $keys = file($apikey_file, FILE_SKIP_EMPTY_LINES | FILE_IGNORE_NEW_LINES);
  foreach($keys as $k){
    if(preg_match('/(^\$key)/', $k)) {
	eval($k);
	break;
    }
  }
*/
} else {
  $key = '';
}

if (isset($_SERVER['PROJECT_HONEY_POT_API_KEY']) && $_SERVER['PROJECT_HONEY_POT_API_KEY'] != '') $key = $_SERVER['PROJECT_HONEY_POT_API_KEY'];

$remote_ip = $_SERVER['REMOTE_ADDR'];

$file = 'http_spam_access.log';
$dir  = '/var/log';
$log  = $dir."/".$file;
$err_log = $dir."/"."http_err.log";
//echo $remote_ip . " - ";
//include_once('httpBL.class.php');
include('project/ProjectHoneyPot.php');
//$bl = new httpBL();

if ($key != '') {
  $php = new ProjectHoneyPot($key);

  //$results = $php->query('182.52.51.155');
  $results = $php->query($remote_ip);

  if (!file_exists($dir)) {
    mkdir ( $dir, 0777, TRUE); 
  }

  if(! empty($results)) {
    if (isset($results['error'])) {
      if (! file_exists($err_log)){
        file_put_contents($err_log, '<?php /*'."\n", FILE_APPEND);
      }
      file_put_contents($err_log, date("Y-m-d H:i:s")." - ".$remote_ip.' - error : '.$results['error']."\n", FILE_APPEND);
    } else {
      if(!empty(array_filter($_REQUEST))) {
        $req = ' request: ';
        foreach($_REQUEST as $k => $v) {
          $req .= $k.' => '.$v.', ';
        }
        $content .= $req;
      } else {
        $req = '';
      }
      $cats = implode(",", $results['categories']);
      $content = date("Y-m-d H:i:s") . " - [" . $remote_ip . "] " . $cats . " score: " . $results['threat_score'] . " last_activity (days): " . $results['last_activity'];
      $content .= " request uri: " . $_SERVER['REQUEST_URI'] . $req . "\n";
    file_put_contents($log, $content, FILE_APPEND);
    }
  }
//Array ( [last_activity] => 1 [threat_score] => 19 [categories] => Array ( [0] => Suspicious [1] => Comment Spammer ) ) 

//print_r($results);
}
?>
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css" integrity="sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T" crossorigin="anonymous">
    <link href="css/signin.css" rel="stylesheet">
  <link rel="apple-touch-icon" sizes="57x57" href="/apple-icon-57x57.png">
  <link rel="apple-touch-icon" sizes="60x60" href="/apple-icon-60x60.png">
  <link rel="apple-touch-icon" sizes="72x72" href="/apple-icon-72x72.png">
  <link rel="apple-touch-icon" sizes="76x76" href="/apple-icon-76x76.png">
  <link rel="apple-touch-icon" sizes="114x114" href="/apple-icon-114x114.png">
  <link rel="apple-touch-icon" sizes="120x120" href="/apple-icon-120x120.png">
  <link rel="apple-touch-icon" sizes="144x144" href="/apple-icon-144x144.png">
  <link rel="apple-touch-icon" sizes="152x152" href="/apple-icon-152x152.png">
  <link rel="apple-touch-icon" sizes="180x180" href="/apple-icon-180x180.png">
  <link rel="icon" type="image/png" sizes="192x192"  href="/android-icon-192x192.png">
  <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png">
  <link rel="icon" type="image/png" sizes="96x96" href="/favicon-96x96.png">
  <link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png">
  <link rel="manifest" href="/manifest.json">
  <meta name="msapplication-TileColor" content="#ffffff">
  <meta name="msapplication-TileImage" content="/ms-icon-144x144.png">
  <meta name="theme-color" content="#fafafa">

    <title>Restricted access</title>
  </head>
  <body class="text-center">
<?php
if ($key == '') { ?>
<p>Sorry, this site is temporary unavailable</p>
<?php } else { ?>
    <form class="form-signin" action="<?php echo $_SERVER['REQUEST_URI'] ?>" method="post">
      <img class="mb-4" src="/android-icon-192x192.png" alt="">
      <h1>Authorized only</h1>
      <h2 class="h3 mb-3 font-weight-normal">Please sign in</h2>
      <label for="inputEmail" class="sr-only">Email address</label>
      <input type="email" id="inputEmail" class="form-control" placeholder="Email address" name="email" required autofocus>
      <label for="inputPassword" class="sr-only">Password</label>
      <input type="password" id="inputPassword" class="form-control" placeholder="Password" name="password" required>
      <div class="checkbox mb-3">
        <label>
          <input type="checkbox" value="remember-me"> Remember me
        </label>
      </div>
      <button class="btn btn-lg btn-primary btn-block" type="submit">Sign in</button>
      <p class="mt-5 mb-3 text-muted">&copy; 2018-∞</p>
    </form>
<?php } ?>
  </body>
    <script src="https://code.jquery.com/jquery-3.3.1.slim.min.js" integrity="sha384-q8i/X+965DzO0rT7abK41JStQIAqVgRVzpbzo5smXKp4YfRvH+8abtTE1Pi6jizo" crossorigin="anonymous"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.7/umd/popper.min.js" integrity="sha384-UO2eT0CpHqdSJQ6hJty5KVphtPhzWj9WO1clHTMGa3JDZwrnQq4sF86dIHNDz0W1" crossorigin="anonymous"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/js/bootstrap.min.js" integrity="sha384-JjSmVgyd0p3pXB1rRibZUAYoIIy6OrQ6VrjIEaFf/nJGzIxFDsf4x0xIM+B07jRM" crossorigin="anonymous"></script>
</html>
