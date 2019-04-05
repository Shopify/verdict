module Verdict
  module Segmenters
    class BetaBernoulliSegmenter < BaseSegmenter

      def initialize(experiment)
        super
      end

      def verify!
        raise Verdict::PriorError, "Prior alpha and beta parameters must be >0 but at least one group has a parameter <0." if groups.values.any? {|v| v.alpha<=0 or v.beta<=0}
      end

      def register_group(handle, alpha=2, beta=2)
        Group.new(experiment, handle, alpha, beta)
      end

      def rng()
        groups.values.map {|g| g.rng}
      end

      def assign(identifier, subject, context = nil)
        prior_draws = rng
        top_draws = prior_draws.each_index.max_by(2){|i| prior_draws[i]} # => select top 2 groups
        groups.values[top_draws.sample(1)[0]] # choose 50/50 between top 2
      end

      def conversion_feedback(identifier, subject, conversion)
        experiment.lookup(subject).group.update_prior conversion.goal, 1-conversion.goal
        return nil
      end

      class Group < Verdict::Group

        attr_reader :alpha, :beta

        def initialize(experiment, handle, alpha, beta)
          super(experiment, handle)
          @alpha = alpha
          @beta = beta
        end

        def update_prior(alpha_update=0, beta_update=0)
          @alpha += alpha_update
          @beta += beta_update
          return nil
        end

        def rng()
          Rubystats::BetaDistribution.new(alpha,beta).rng
        end

        def to_s
          "#{handle} (alpha #{alpha}, beta #{beta})"
        end

        def as_json(options = {})
          super(options).merge(alpha:alpha, beta:beta)
        end
      end

      class << self
        attr_accessor :salt
      end
    end
  end
end
