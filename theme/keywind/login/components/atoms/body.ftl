<#macro kw>
	<style>
		a {color:red;}
		.body-margin {
			margin-top: 2rem;
		}
	</style>
	<body class="bg-secondary-100 flex flex-col items-center body-margin">
    	<#nested>
		<div class="gap-4 grid grid-cols-3">
			<a href="https://topfilms.io/contact" style="">Contact</a>
			<a href="https://topfilms.io/privacy" style="">Privacy</a>
			<a href="https://topfilms.io/terms" style="">Terms</a>
		</div>
	</body>
</#macro>
