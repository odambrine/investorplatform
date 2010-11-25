# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_investorplatform_session',
  :secret      => 'ace1c74c7c0b633f887b83b2927c7a7619a82d59f5d02692abfaa2127c7f94d8ab55c02cb30e25f4262243086eab98cb0661fa56da747c08bd47b7c0d8f8329f'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
