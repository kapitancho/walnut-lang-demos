<?php

use Walnut\Lang\Blueprint\Execution\AnalyserException;
use Walnut\Lang\Blueprint\NativeCode\NativeCodeContext;
use Walnut\Lang\Implementation\Compilation\WalexLexerAdapter;
use Walnut\Lang\Implementation\Compilation\ParserException;
use Walnut\Lang\Implementation\Compilation\TransitionLogger;
use Walnut\Lang\Implementation\Registry\ProgramBuilderFactory;
use Walnut\Lang\NativeConnector\Cli\Implementation\CliAdapter;

require_once __DIR__ . '/../vendor/autoload.php';

$input = $argv ?? [
	...[0],
	...(($_GET['src'] ?? null) ? [$_GET['src']] : []),
];
array_shift($input);
$source = array_shift($input);
$sources = [];

$sourceRoot = __DIR__ . '/../walnut-src';

foreach(glob("$sourceRoot/*.nut") as $sourceFile) {
	$sources[] = str_replace('.nut', '', basename($sourceFile));
}

if ($_GET['check'] ?? null === 'all') {
	$lexer = new WalexLexerAdapter();
	$logger = new TransitionLogger();
	echo '<pre>';
	foreach($sources as $source) {
		$sourceCode = file_get_contents("$sourceRoot/$source.nut");
		$tokens = $lexer->tokensFromSource($sourceCode);
		$pb = ($pbf = new ProgramBuilderFactory())->getProgramBuilder();
		$moduleImporter = new Walnut\Lang\Implementation\Compilation\ModuleImporter($sourceRoot, $pb, $logger);
		$parser = new Walnut\Lang\Implementation\Compilation\Parser($pb, $logger, $moduleImporter);
		try {
			$m = $parser->programFromTokens($tokens);
			$pb->build()->analyse();
			echo "OK: $source\n";
		} catch (AnalyserException $e) {
			echo "Analyse error in $source: {$e->getMessage()}\n";
		} catch (ParserException $e) {
			echo "Parse error in $source: {$e->getMessage()}\n";
		}
	}
	die;
}

if (!in_array($source, $sources, true)) {
	$source = 'cast10';
}
$qs = [
	'cast4' => '&parameters[]=4',
	'cast7' => '&parameters[]=3&parameters[]=4',
	'cast8' => '&parameters[]=29&parameters[]=15&parameters[]=51&parameters[]=31&parameters[]=211',
	'cast9' => '&parameters[]=30',
	'cast10' => '&parameters[]=3&parameters[]=3.14',
][$source] ?? '';
$generate = ($input[0] ?? null) === '-g' && array_shift($input);
$cached = ($input[0] ?? null) === '-c' && array_shift($input);

$sourceCode = file_get_contents("$sourceRoot/$source.nut");

$lexer = new WalexLexerAdapter();
$tokens = $lexer->tokensFromSource($sourceCode);

$isRun = $_GET['run'] ?? null;


$pb = ($pbf = new ProgramBuilderFactory())->getProgramBuilder();
$logger = new TransitionLogger();
$moduleImporter = new Walnut\Lang\Implementation\Compilation\ModuleImporter($sourceRoot, $pb, $logger);
$parser = new Walnut\Lang\Implementation\Compilation\Parser($pb, $logger, $moduleImporter);
try {
	ob_start();
	$m = $parser->programFromTokens($tokens);
	$debug = ob_get_clean();

	foreach(array_slice(array_reverse($tokens), 1) as $token) {
		$sourceCode = substr_replace($sourceCode, '<strong title="' . $token->rule->tag . '">' .
			htmlspecialchars($token->patternMatch->text) . '</strong>', $token->sourcePosition->offset, strlen($token->patternMatch->text));
	}
	if (!$isRun) { include __DIR__ . '/code.tpl.php'; }

} catch (ParserException $e) {
	$debug = ob_get_clean();
	echo htmlspecialchars("Error: {$e->getMessage()}\n");

	foreach(array_reverse(array_slice($tokens, 0, $e->state->i)) as $token) {
		$sourceCode = substr_replace($sourceCode, '<strong title="' . $token->rule->tag . '">' .
			htmlspecialchars($token->patternMatch->text) . '</strong>', $token->sourcePosition->offset, strlen($token->patternMatch->text));
	}
	if (!$isRun) {
		ob_start();
		echo $logger, PHP_EOL;
		var_dump($tokens);
		$debug = ob_get_clean();
		include __DIR__ . '/code.tpl.php';

		echo '<pre>', $e->getTraceAsString();
		die;
	}
}

//echo '<pre>', $debug;
if ($isRun) {
	try {
		$cliAdapter = new CliAdapter(
			$pb,
            new NativeCodeContext(
			    $pbf->typeRegistry,
			    $pbf->valueRegistry
            )
		);
		$content = $cliAdapter->execute(... $_GET['parameters'] ?? []);
	} catch (Exception $e) {
		/*foreach($e->getTrace() as $t) {
			echo implode('<br>', array_map(fn($arg) =>
				$arg instanceof Type || $arg instanceof Value ? (string)$arg : (is_object($arg) ? $arg::class : json_encode($arg)), $t['args']));
			echo '<hr/>';
		}*/
		$content = '<pre>' . htmlspecialchars($e::class . ' | ' . PHP_EOL . $e . ' | ' . PHP_EOL . $e->getMessage()) . '</pre>';
	}
	$program = $sourceCode;
	$output = $debug;
	include __DIR__ . '/exec.tpl.php';
}