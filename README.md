# MakeMarket

MakeMarket is an early digital-marketplace MVP for original creations. The site includes a discovery page, search and categories, saved products, creator profiles, email account flows, and listing submissions that remain pending review.

## Deploy

The GitHub Actions workflow in `.github/workflows/pages.yml` publishes the repository with GitHub Pages when a commit reaches `main`. In the repository, open **Settings → Pages** and select **GitHub Actions** as the build and deployment source if GitHub Pages is not already enabled. The published address will be `https://harry7j3.github.io/MAKEMARKET/`.

For email confirmation, password reset, and OAuth to return to the hosted site, a project owner must set the Supabase Auth Site URL to `https://harry7j3.github.io/MAKEMARKET/` and add that same URL to the allowed redirect URLs in Supabase Authentication URL Configuration. Google and Apple sign-in also need their own provider credentials configured in Supabase.

`config.js` contains the Supabase URL and publishable browser key. These values are intended to be public; never put a Supabase service-role key, private key, Stripe secret, or other secret in the website repository.

## MVP limits

This is an early preview, not a production store. Checkout, creator payouts, tipping, digital file delivery, listing image uploads, moderation tools, privacy/consumer terms, and deployment review still need work. Do not accept real orders or upload sensitive information. Supabase database rows are protected by the policies in `supabase/schema.sql`; keep row-level security enabled.

If the founder is under 18, a parent or guardian should review and manage hosting, account settings, contracts, payments, privacy practices, platform rules, creator rights, and UK tax responsibilities before inviting the public or selling anything.

