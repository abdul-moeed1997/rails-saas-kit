# rails-saas-kit

Everything you need to launch a Rails SaaS — authentication, Stripe subscriptions, multi-tenant accounts, background jobs, admin dashboard, Docker, and Kamal deployment. Fork it and start building.

## Background jobs

This app uses [Solid Queue](https://github.com/rails/solid_queue) (Rails 8 default) for background processing via Active Job.

### Running workers locally

Start the web server, CSS watcher, and job worker together:

```bash
bin/dev
```

Or run the worker in a separate terminal:

```bash
bin/jobs
```

Alternative (matches production Kamal setup): run Solid Queue inside Puma:

```bash
SOLID_QUEUE_IN_PUMA=true bin/rails server
```

On first setup, load Solid Queue tables into the development database:

```bash
bin/rails db:schema:load:queue
```

### Job dashboard (Mission Control)

Solid Queue's admin UI is provided by [Mission Control – Jobs](https://github.com/rails/mission_control-jobs), mounted at `/jobs` (similar to Sidekiq Web).

Development credentials (HTTP Basic Auth):

- Username: `dev`
- Password: `dev`

Override with `MISSION_CONTROL_USERNAME` and `MISSION_CONTROL_PASSWORD` if needed.

Production: configure credentials with:

```bash
RAILS_ENV=production bin/rails mission_control:jobs:authentication:configure
```

### Example: welcome email on signup

When a founder signs up (`POST /users`), `WelcomeEmailJob` is enqueued on the `mailers` queue. The job delivers `UserMailer#welcome` asynchronously. In development, emails open in the browser via Letter Opener after the worker processes the job.
