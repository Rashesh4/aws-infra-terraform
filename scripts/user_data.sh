#!/bin/bash
# =============================================================================
# EC2 User Data Script — Bootstraps nginx web server
# Runs automatically on first boot of the EC2 instance
# =============================================================================

set -euxo pipefail

# Update system packages
dnf update -y

# Install nginx
dnf install -y nginx

# Create a custom landing page
cat > /usr/share/nginx/html/index.html << 'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Web Platform — Deployed by Terraform</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
            background: linear-gradient(135deg, #0f0c29, #302b63, #24243e);
            color: #fff;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            text-align: center;
            padding: 3rem;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 20px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            max-width: 600px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        }
        h1 { font-size: 2.5rem; margin-bottom: 1rem; }
        .highlight { color: #00d4ff; }
        p { font-size: 1.1rem; opacity: 0.8; line-height: 1.6; }
        .meta { margin-top: 2rem; font-size: 0.85rem; opacity: 0.5; }
        .stack {
            display: flex;
            gap: 1rem;
            justify-content: center;
            margin-top: 1.5rem;
            flex-wrap: wrap;
        }
        .badge {
            padding: 0.4rem 1rem;
            background: rgba(0, 212, 255, 0.15);
            border: 1px solid rgba(0, 212, 255, 0.3);
            border-radius: 20px;
            font-size: 0.85rem;
            color: #00d4ff;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 <span class="highlight">Web Platform</span></h1>
        <p>
            Infrastructure provisioned with Terraform Registry modules.<br>
            Server configured and deployed automatically.
        </p>
        <div class="stack">
            <span class="badge">Terraform</span>
            <span class="badge">AWS</span>
            <span class="badge">Nginx</span>
            <span class="badge">GitHub Actions</span>
        </div>
        <p class="meta">Deployed by Rashesh | Environment: dev</p>
    </div>
</body>
</html>
HTML

# Enable and start nginx
systemctl enable nginx
systemctl start nginx

# Log completion
echo "$(date '+%Y-%m-%d %H:%M:%S') - User data script completed successfully" >> /var/log/user-data.log
