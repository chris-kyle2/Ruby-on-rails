FROM ruby:3.1.2-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    postgresql-client \
    nodejs \
    npm \
    git \
    curl \
    libssl-dev \
    shared-mime-info \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy dependency files
COPY Gemfile Gemfile.lock ./

# Install Ruby dependencies
RUN gem install bundler && \
    bundle config set without 'development test' && \
    bundle install --jobs 20 --retry 5

# Copy package.json for any npm dependencies
COPY package.json ./

# Install npm dependencies if any
RUN npm install

# Copy application code
COPY . ./

# Set Rails environment
ENV RAILS_ENV=production
ENV NODE_ENV=production

# Precompile assets
RUN SECRET_KEY_BASE=dummy \
    bundle exec rails assets:precompile

# Add a script to be executed every time the container starts
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

EXPOSE 3000

# Start the main process
CMD ["rails", "server", "-b", "0.0.0.0"] 