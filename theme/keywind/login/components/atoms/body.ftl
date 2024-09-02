<#macro kw>
	<style>
		.link {
			color: #fff;
			font-size: 14px;
		}

		.link:hover {
			opacity: 0.7;
			text-decoration: underline;
			cursor: pointer;
		}

		.body-margin {
			margin-top: 2rem;
		}

		.background-color {
			background-color: #309cf2;
		}
	</style>
	<body class="flex flex-col items-center body-margin background-color">
    	<#nested>
		<div class="gap-4 grid grid-cols-3 mt-2">
			<a href="https://topfilms.io/contact" class="link">Contact</a>
			<a href="https://topfilms.io/privacy" class="link">Privacy</a>
			<a href="https://topfilms.io/terms" class="link">Terms</a>
		</div>
	</body>
</#macro>
