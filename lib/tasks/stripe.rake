namespace :stripe do
  desc "Sync local plans and prices to Stripe (creates products/prices, saves IDs)"
  task sync_catalog: :environment do
    Plan.find_each do |plan|
      if plan.stripe_product_id.present?
        product = Stripe::Product.retrieve(plan.stripe_product_id)
        Stripe::Product.update(product.id, name: plan.name, description: plan.description, active: plan.status == "active")
      else
        product = Stripe::Product.create(
          name: plan.name,
          description: plan.description,
          active: plan.status == "active",
          metadata: { plan_slug: plan.slug }
        )
        plan.update!(stripe_product_id: product.id)
      end

      plan.prices.active.find_each do |price|
        next if price.amount_cents.zero?

        if price.stripe_price_id.present?
          existing = Stripe::Price.retrieve(price.stripe_price_id)
          unless existing.active
            Stripe::Price.update(existing.id, active: true)
          end
          next
        end

        stripe_price = Stripe::Price.create(
          product: plan.stripe_product_id,
          unit_amount: price.amount_cents,
          currency: price.currency,
          recurring: { interval: price.interval },
          metadata: { plan_slug: plan.slug, interval: price.interval }
        )
        price.update!(stripe_price_id: stripe_price.id)
      end

      puts "Synced #{plan.name} (#{plan.slug})"
    end
  end
end
