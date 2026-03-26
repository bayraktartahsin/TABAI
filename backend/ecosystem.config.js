module.exports = {
	apps: [
		{
			name: "tai-api",
			script: "src/server.ts",
			interpreter: "node",
			interpreter_args: "--import tsx",
			cwd: "/var/www/tai/backend",
			env: {
				NODE_ENV: "production",
			},
			instances: 1,
			autorestart: true,
			max_memory_restart: "512M",
			error_file: "/var/log/tai/error.log",
			out_file: "/var/log/tai/out.log",
			merge_logs: true,
		},
	],
};
