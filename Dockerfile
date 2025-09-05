# Use an official Ruby runtime as a parent image
FROM ruby:3.4.5

# Set the working directory in the container
WORKDIR /app

# Copy Gemfile and Gemfile.lock first for better caching
COPY Gemfile Gemfile.lock ./

# Install dependencies
RUN bundle install

# Copy the current directory contents into the container at /app
COPY . /app

# Expose the port the server runs on
EXPOSE 3000

# Run the server when the container launches
CMD ["bundle", "exec", "ruby", "async_fiber_server.rb"]
