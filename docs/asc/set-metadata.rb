require 'openssl'; require 'base64'; require 'json'; require 'net/http'; require 'uri'
cfg = JSON.parse(File.read(File.expand_path('~/.vibe-aso/config.json')))['asc']
KEY = OpenSSL::PKey::EC.new(File.read(File.expand_path(cfg['p8_path'])))
def b64(d)
  Base64.urlsafe_encode64(d).delete('=')
end
now = Time.now.to_i
si = "#{b64(JSON.dump({alg:'ES256',kid:cfg['key_id'],typ:'JWT'}))}.#{b64(JSON.dump({iss:cfg['issuer_id'],iat:now,exp:now+1200,aud:'appstoreconnect-v1'}))}"
asn = OpenSSL::ASN1.decode(KEY.sign(OpenSSL::Digest::SHA256.new, si))
TOKEN = "#{si}.#{b64(asn.value[0].value.to_s(2).rjust(32,"\x00") + asn.value[1].value.to_s(2).rjust(32,"\x00"))}"
HTTP = Net::HTTP.start('api.appstoreconnect.apple.com', 443, use_ssl: true)
def call(m, path, body=nil)
  req = Object.const_get("Net::HTTP::#{m.capitalize}").new(URI("https://api.appstoreconnect.apple.com#{path}"))
  req['Authorization'] = "Bearer #{TOKEN}"; req['Content-Type'] = 'application/json'
  req.body = JSON.generate(body) if body
  res = HTTP.request(req)
  [res.code.to_i, (JSON.parse(res.body) rescue {})]
end

DESC = <<~TXT.strip
  Four photo tools that do their job and get out of the way. Every tool runs on your iPhone, so your photos never leave the device.

  CONVERT
  Turn HEIC shots from your camera into JPG or PNG that opens anywhere. Or put several photos into a single PDF, one page each, in the order you picked them.

  IMAGE SIZE
  Resize by percent, by preset, or to an exact pixel size. Fit any aspect ratio without cropping anything, or fill the frame and drag the photo to the framing you want. Set 72, 150 or 300 DPI when a print shop asks for it.

  COMPRESS
  Drag the quality slider and watch the file size change before you commit. For email, upload forms and anything with a size limit.

  BLUR
  Paint over faces, licence plates, addresses or screenshots you would rather not share as they are. Adjust the strength and the brush size, and the result is rendered at full resolution.

  BUILT TO BE QUICK
  - Works offline: no account, no sign-up, nothing to wait for
  - Batch: one setting applied to up to 20 photos at once
  - Results are named by tool and date, so you can find them later
  - Save straight to Photos or send them on from the share sheet
TXT

PROMO = "Convert HEIC, resize to any size or ratio, compress to fit a limit, and blur what you would rather not share. All on your iPhone."
KEYWORDS = "png,dpi,resize,crop,picture,batch,maker,jpeg,face,print,kb,compressor,square,fit"
SUBTITLE = "Blur, JPG & HEIC Converter"

puts "описание #{DESC.length}/4000, промо #{PROMO.length}/170, ключи #{KEYWORDS.length}/100, сабтайтл #{SUBTITLE.length}/30"

c, d = call('PATCH', '/v1/appInfoLocalizations/fb048df7-4762-4e15-b2e5-ba1cd87771da', {
  data: { type: 'appInfoLocalizations', id: 'fb048df7-4762-4e15-b2e5-ba1cd87771da',
          attributes: { subtitle: SUBTITLE } } })
puts "сабтайтл: #{c} #{d.dig('errors',0,'detail')}"

c, d = call('PATCH', '/v1/appStoreVersionLocalizations/3cf53a25-49e7-465b-b817-d2030c2f5710', {
  data: { type: 'appStoreVersionLocalizations', id: '3cf53a25-49e7-465b-b817-d2030c2f5710',
          attributes: { description: DESC, keywords: KEYWORDS, promotionalText: PROMO } } })
puts "описание и ключи: #{c} #{d.dig('errors',0,'detail')}"

# читаем обратно — 2xx это не подтверждение
c, d = call('GET', '/v1/appStoreVersionLocalizations/3cf53a25-49e7-465b-b817-d2030c2f5710')
a = d.dig('data','attributes') || {}
puts "проверка: keywords=#{a['keywords'].to_s[0,40]}… | описание #{a['description'].to_s.length} симв. | промо #{a['promotionalText'].to_s.length} симв."
c, d = call('GET', '/v1/appInfoLocalizations/fb048df7-4762-4e15-b2e5-ba1cd87771da')
a = d.dig('data','attributes') || {}
puts "проверка: name=#{a['name']} | subtitle=#{a['subtitle']}"
