#!/usr/bin/env zsh

set -e
set -o pipefail
set -u

echo "🔍 Running Tofu plan..."
if ! tofu plan -out=tfplan 2>&1 | tee plan.log; then
    echo "❌ Plan failed. Checking for missing zones..."

    # Check if the error is related to a missing DNS zone
    if grep -q "\-target planning" plan.log; then
        echo "⚠️ Missing DNS zones detected. Creating them first..."

        # Apply only the zone creation step
        tofu apply -target=hetznerdns_zone.zone

        echo "🔄 Re-running full plan after zone creation..."
        if ! tofu plan -out=tfplan 2>&1 | tee plan.log; then
            echo "❌ Plan failed even after zone creation. Exiting."
            exit 1
        fi
    else
        echo "❌ Plan failed due to an unknown issue. Exiting."
        exit 1
    fi
fi

#applying a planfile skips confirmations...
echo "✅ Plan successful. Ready to apply changes."
echo "Do you want to apply these changes? (y/n)"
read -r apply_confirmation

if [[ "$apply_confirmation" =~ ^[Yy]$ ]]; then
    echo "🔄 Applying changes..."
    tofu apply tfplan
    echo "🎉 Apply complete!"
else
    echo "❌ Apply aborted by user."
    exit 1
fi