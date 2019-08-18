require 'cloudflare'
require 'openssl'

class HelperMethods
	def self.statusCertificate
		#check in db
		#if exist return date of generation and date of maturity
		
		#if does not exist in db return status unavailable
	end

	def self.generatePKey
		private_key = OpenSSL::PKey::RSA.new(4096)
		# store it in a file with any encryption
		encryptPKey(private_key)
	end

	def self.encryptPKey(private_key)
		cipher = OpenSSL::Cipher.new 'AES-128-CBC'
		pass_phrase = 'my secure pass phrase goes here'

		key_secure = private_key.export cipher, pass_phrase

		open 'private.secure.pem', 'w' do |io|
  			io.write key_secure
		end
	end

	def self.decryptPKey
		if !File.exist?('private.secure.pem')
			generatePKey
		end
		key_pem = File.read 'private.secure.pem'
		pass_phrase = 'my secure pass phrase goes here'
		key = OpenSSL::PKey::RSA.new key_pem, pass_phrase
		return key
	end
	
	def self.setupClient
		private_key = decryptPKey
		client = Acme::Client.new(private_key: private_key, directory: 'https://acme-staging-v02.api.letsencrypt.org/directory')
		# mail id to get certificate expiry alert etc.
		account = client.new_account(contact: 'mailto:linkaditya29@gmail.com', terms_of_service_agreed: true)
		# return kid
		key_id = account.kid
		open 'key_id', 'w' do |io|
			io.write key_id
	  	end
	end

	def self.initiateGeneration
		private_key = decryptPKey
		if !File.exist?('key_id')
			setupClient
		end
		@kid = File.read 'key_id'
		@client = Acme::Client.new(private_key: private_key, directory: 'https://acme-staging-v02.api.letsencrypt.org/directory', kid: @kid)
		@order = @client.new_order(identifiers: ['amahi.linksam.tk'])
		@authorization = @order.authorizations.first
		@dns_challenge = @authorization.dns
	end

	def self.initiateChallenge
		@challenge_name = @dns_challenge.record_name # => '_acme-challenge'
		@challenge_record_type = @dns_challenge.record_type # => 'TXT'
		@challenge_key = @dns_challenge.record_content # => 'HRV3PS5sRDyV-ous4HJk4z24s5JjmUTjcCaUjFt28-8'
	end

	def self.addDNSRecord
		# challenge name for dns-01 verification method
		@challenge_name = @dns_challenge.record_name # => '_acme-challenge'
		# challenge key for verification
		@challenge_key = @dns_challenge.record_content # => 'HRV3PS5sRDyV-ous4HJk4z24s5JjmUTjcCaUjFt28-8'
		# record type for verification
		@challenge_record_type = @dns_challenge.record_type # => 'TXT'

		# cloudflare credentials
		#registered email with cloudflare
		@email = ''
		# global api key
		@key = ''

		Cloudflare.connect(key: @key, email: @email) do |connection|
			# Add a DNS record. We need to add TXT DNS record with auto-generated value 
			#to be verify domain ownership with Let's Encrypt
			zone_to_update = "#{@challenge_name}.#{@subdomain_name}"
			zone = connection.zones.find_by_name(@domain_name)
			zone.dns_records.create(@challenge_record_type, zone_to_update, @challenge_key)
		end
	end

	def self.verifyDNSEntry
		#dig -t txt @challenge_name.@sudomain.@domain
		#if if found valid value then return true else wait
		cmd = "dig -t txt #{@challenge_name}.#{@subdomain_name}.#{@domain_name} +short"
		value = `#{cmd}`
		while value == ""
			sleep(2)
			value = `#{cmd}`
		end
	end

	def self.completeChallenge
		@dns_challenge.request_validation
		while @dns_challenge.status == 'pending'
			sleep(2)
			@dns_challenge.reload
		end
		@dns_challenge.status # => 'valid'
	end

	def self.downloadCertificate
		#generate a different private key
		a_different_private_key = OpenSSL::PKey::RSA.new(4096)
		common_name = "#{@subdomain_name}.#{@domain_name}"
		csr = Acme::Client::CertificateRequest.new(private_key: a_different_private_key, subject: { common_name: common_name })
		@order.finalize(csr: csr)
		while @order.status == 'processing'
  			sleep(1)
  			@dns_challenge.reload
		end
		cert = @order.certificate # => PEM-formatted certificate
		open 'cert.pem', 'w' do |io|
			io.write cert
		end	  
	end

	def self.cleanupDNSEntry
		@record = "#{@challenge_name}.#{@subdomain_name}.#{@domain_name}"
		Cloudflare.connect(key: @key, email: @email) do |connection|
			# Remove DNS entry
		
			zone = connection.zones.find_by_name(@domain)
			zone.dns_records.find_by_name(@record).delete
		end
		return "inserted succesfully"
	end

	def self.certificateDispatch
		#store/update certificate in DB
		#send certificate to client
	end

	def self.revokeCertificate
		private_key = decryptPKey
		cert_key = File.read 'cert.pem'
		client = Acme::Client.new(private_key: private_key, directory: 'https://acme-staging-v02.api.letsencrypt.org/directory')
		client.revoke(certificate: cert_key)
	end

	def self.renewCertificate
		# renew is just placing a new order and replacing the old certificate
		generateCertificate
	end

	def self.generateCertificate(params)
		#find if account private key file exist true then continue
		#else generate new file
		sub_dom_name = params[:hda_name]
		dom_name = params[:domain]

		@subdomain_name = sub_dom_name
		@domain_name = dom_name
		puts(@subdom_name)
		puts(@dom_name)

		#initiateGeneration
		#initiateChallenge
		#addDNSRecord
		#verifyDNSEntry
		#completeChallenge
		#downloadCertificate
		#cleanupDNSEntry
		#certificateDispatch

		return true
	end
end