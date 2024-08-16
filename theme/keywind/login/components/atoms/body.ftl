<#macro kw>
	<style>
		.link {
			color: #4c5563;
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
	</style>
	<body class="bg-secondary-100 flex flex-col items-center body-margin">
    	<#nested>
		<div class="gap-4 grid grid-cols-3 mt-1">
			<a href="https://topfilms.io/contact" class="link">Contact</a>
			<a href="https://topfilms.io/privacy" class="link">Privacy</a>
			<a href="https://topfilms.io/terms" class="link">Terms</a>
		</div>
	</body>
</#macro>
