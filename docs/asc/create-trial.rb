require 'openssl'; require 'base64'; require 'json'; require 'net/http'; require 'uri'
cfg = JSON.parse(File.read(File.expand_path('~/.vibe-aso/config.json')))['asc']
KEY = OpenSSL::PKey::EC.new(File.read(File.expand_path(cfg['p8_path'])))
def b64(d)
  Base64.urlsafe_encode64(d).delete('=')
end
def jwt(cfg)
  now = Time.now.to_i
  si = "#{b64(JSON.dump({alg:'ES256',kid:cfg['key_id'],typ:'JWT'}))}.#{b64(JSON.dump({iss:cfg['issuer_id'],iat:now,exp:now+1200,aud:'appstoreconnect-v1'}))}"
  asn = OpenSSL::ASN1.decode(KEY.sign(OpenSSL::Digest::SHA256.new, si))
  r = asn.value[0].value.to_s(2).rjust(32,"\x00"); s = asn.value[1].value.to_s(2).rjust(32,"\x00")
  "#{si}.#{b64(r+s)}"
end
TOKEN = jwt(cfg)
HTTP = Net::HTTP.start('api.appstoreconnect.apple.com', 443, use_ssl: true)
def call(m, path, body=nil)
  req = Object.const_get("Net::HTTP::#{m.capitalize}").new(URI("https://api.appstoreconnect.apple.com#{path}"))
  req['Authorization'] = "Bearer #{TOKEN}"; req['Content-Type'] = 'application/json'
  req.body = JSON.generate(body) if body
  res = HTTP.request(req)
  [res.code.to_i, (JSON.parse(res.body) rescue {})]
end

sub = JSON.parse(File.read('/tmp/sub_ids.json'))['sub']
_, t = call('GET', '/v1/territories?limit=200')
terrs = t['data'].map { |x| x['id'] }
ok = 0; fails = Hash.new(0)
terrs.each do |id|
  c, d = call('POST', '/v1/subscriptionIntroductoryOffers', {
    data: { type: 'subscriptionIntroductoryOffers',
      attributes: { duration: 'ONE_WEEK', offerMode: 'FREE_TRIAL', numberOfPeriods: 1 },
      relationships: { subscription: { data: { type: 'subscriptions', id: sub } },
                       territory: { data: { type: 'territories', id: id } } } } })
  if c < 300 then ok += 1
  else fails[(d['errors']&.first&.dig('detail') || c.to_s)[0, 90]] += 1 end
end
puts "триал создан для территорий: #{ok} из #{terrs.size}"
fails.each { |k, v| puts "  не вышло (#{v}): #{k}" }
