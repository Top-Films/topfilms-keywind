<#macro kw>
	<style>
		.link {
			color: #c9c9c9;
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
			background-color: #242424;
		}

		a {
			color: #309cf2 !important;
		}

		span > a {
			color: #c9c9c9 !important;
		}
	</style>
	<body class="flex flex-col items-center body-margin background-color">
    	<#nested>
		<div class="gap-4 grid grid-cols-3 mt-2">
			<span><a href="https://topfilms.io/contact" class="link">Contact</a><span>
			<span><a href="https://topfilms.io/privacy" class="link">Privacy</a><span>
			<span><a href="https://topfilms.io/terms" class="link">Terms</a><span>
		</div>
	</body>
</#macro>
