require 'json'

###
# terraformer_filter.rb
# terraformerで出力したroute53を特定のゾーンでフィルタリング
#
# 実行方法
# 1. terraformerでRoute53のレコードを出力
#   terraformer plan aws --regions=ap-northeast-1 --resources=route53
# 2. ゾーンでフィルタ
#   terraformer_filter.rb <zone_id>
#   実行後に<zone.id>.jsonが出力されます
# 3. Import
#   terraform import plan <zone.id>.json

def same_zone_id?(resource, zone_id)
  resource['InstanceState']['id'] == zone_id or resource['InstanceState']['attributes']['zone_id'] == zone_id
end

def format_resource_name(resource_name, zone_id)
  resource_name
      .gsub(/^#{zone_id}_/, '')
      .gsub(/--/,'_')
      .gsub(/_{2,}/,'_')
      .gsub(/_$/, '')
end

def format_zone_id(resource_id, zone_id)
  resource_id
      .gsub(/aws_route53_zone.#{zone_id}_/, 'aws_route53_zone.')
      .gsub(/--/,'_')
      .gsub(/_{2,}/,'_')
end

zone_id = ARGV[0]

if zone_id.nil?
  p("specify zone_id")
  exit 1
end

in_filename = 'plan.json'
out_filename = zone_id + '.json'

hash = {}

File.open(in_filename) do |in_file|
  hash = JSON.load(in_file)
end


hash['ImportedResource'].each do |resource_name, resources|
  # zone_idが一致しない要素を削除
  resources.delete_if{|resource|
    not same_zone_id?(resource, zone_id)
  }

  resources.each do |resource|
    resource['ResourceName'] = format_resource_name(resource['ResourceName'], zone_id)
    if resource['InstanceInfo']['Type'] == 'aws_route53_record'
      resource['Item']['zone_id'] = format_zone_id(resource['Item']['zone_id'], zone_id)
    end
  end
  printf("%d recourds found.", resources.count)
end

print("")

File.open(out_filename, 'w') do |ofile|
    j = JSON.dump(hash, ofile)
end

