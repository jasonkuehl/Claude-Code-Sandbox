# Security Policy

## Scope

This project is a **local development sandbox** — it runs on your machine and is not
intended to be exposed to the internet. Please keep that context in mind when evaluating
findings.

## Reporting a Vulnerability

If you find a security issue, please **do not open a public GitHub issue**.

Email: jason@jasonkuehl.com  
Subject line: `[SECURITY] claude-sandbox — <brief description>`

Include:
- Description of the issue and potential impact
- Steps to reproduce
- Any suggested mitigations

You can expect an acknowledgement within 48 hours and a fix or mitigation plan within
14 days for confirmed issues.

## Known Accepted Risks

- **Root SSH access**: The VS Code SSH container allows `root` login by password. This is
  intentional for local dev ergonomics. Never expose port 2222 beyond localhost.
  
- **SSH password auth**: Password auth is enabled for VS Code compatibility. Use a strong
  `SSH_PASSWORD` in your `.env` and do not expose port 2222 to a network.
