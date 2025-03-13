#!/usr/bin/env ruby
# encoding: utf-8

# mib2zabbix_simple.rb - MIB dosyalarını Zabbix'e aktarma aracı (Basitleştirilmiş versiyon)
# Kullanım: ruby mib2zabbix_simple.rb <mib_dosyası> [çıktı_dosyası]

require 'optparse'
require 'fileutils'
require 'json'

class MIB2Zabbix
  attr_reader :mib_file, :output_file, :verbose

  def initialize(options)
    @mib_file = options[:mib_file]
    @output_file = options[:output_file]
    @verbose = options[:verbose] || false
    @template_name = options[:template_name] || File.basename(@mib_file, '.*')
    @groups = options[:groups] || ["Templates/Network devices"]
  end

  def run
    puts "MIB dosyası işleniyor: #{@mib_file}" if @verbose
    
    unless File.exist?(@mib_file)
      puts "Hata: MIB dosyası bulunamadı: #{@mib_file}"
      exit 1
    end
    
    mib_data = parse_mib_file
    zabbix_template = convert_to_zabbix_template(mib_data)
    
    if @output_file
      save_template_to_file(zabbix_template)
    else
      puts JSON.pretty_generate(zabbix_template)
    end
    
    puts "İşlem tamamlandı!" if @verbose
  end
  
  private
  
  def parse_mib_file
    puts "MIB dosyası ayrıştırılıyor..." if @verbose
    
    mib_data = {
      name: @template_name,
      oids: []
    }
    
    # Basit bir ayrıştırma yöntemi kullan
    content = File.read(@mib_file)
    
    # OID tanımlarını bul
    object_types = content.scan(/(\w+)\s+OBJECT-TYPE/)
    object_types.each do |match|
      name = match[0]
      
      # Açıklama bul
      description_match = content.match(/#{name}\s+OBJECT-TYPE.*?DESCRIPTION\s+"([^"]+)"/m)
      description = description_match ? description_match[1].gsub(/\s+/, ' ').strip : "#{name} OID"
      
      # Tip bul
      syntax_match = content.match(/#{name}\s+OBJECT-TYPE.*?SYNTAX\s+([^\s\n]+)/m)
      type = syntax_match ? syntax_match[1].strip : 'OCTETSTR'
      
      # Erişim bul
      access_match = content.match(/#{name}\s+OBJECT-TYPE.*?(ACCESS|MAX-ACCESS)\s+([^\s\n]+)/m)
      access = access_match ? access_match[2].strip : 'read-only'
      
      # OID'yi bul
      oid_match = content.match(/#{name}\s+OBJECT-TYPE.*?::=\s*{\s*[\w\d]+\s*(\d+)\s*}/m)
      
      if oid_match
        oid_suffix = oid_match[1]
        
        # Tam OID yolunu oluştur (basitleştirilmiş)
        full_oid = ".1.3.6.1.4.1.#{oid_suffix}"
        
        mib_data[:oids] << {
          oid: full_oid,
          name: name,
          description: description,
          type: type,
          access: access
        }
      end
    end
    
    puts "Toplam #{mib_data[:oids].size} OID bulundu" if @verbose
    mib_data
  end
  
  def convert_to_zabbix_template(mib_data)
    puts "Zabbix şablonuna dönüştürülüyor..." if @verbose
    
    # Grupları hazırla
    groups = @groups.map { |group| { name: group } }
    
    template = {
      zabbix_export: {
        version: "5.0",
        date: Time.now.strftime("%Y-%m-%dT%H:%M:%SZ"),
        groups: groups,
        templates: [
          {
            template: "Template #{mib_data[:name]}",
            name: "Template #{mib_data[:name]}",
            description: "Generated from MIB file: #{File.basename(@mib_file)}",
            groups: groups,
            applications: [
              {
                name: mib_data[:name]
              }
            ],
            items: [],
            discovery_rules: []
          }
        ]
      }
    }
    
    # OID'leri Zabbix öğelerine dönüştür
    mib_data[:oids].each do |oid|
      item = {
        name: oid[:name],
        type: "SNMP_AGENT",
        snmp_oid: oid[:oid],
        key: "snmp.#{oid[:name].downcase.gsub(/[^a-z0-9]/, '_')}",
        delay: "5m",
        history: "2w",
        trends: "365d",
        status: "0",
        value_type: get_value_type(oid[:type]),
        description: oid[:description],
        applications: [
          {
            name: mib_data[:name]
          }
        ],
        preprocessing: [],
        tags: [
          {
            tag: "mib",
            value: mib_data[:name]
          }
        ]
      }
      
      template[:zabbix_export][:templates][0][:items] << item
    end
    
    template
  end
  
  def get_value_type(mib_type)
    case mib_type
    when 'INTEGER', 'Integer32', 'Counter32', 'Counter64', 'Gauge32', 'TimeTicks'
      "3" # Numeric unsigned
    when 'OCTETSTR', 'DisplayString', 'OBJECTIDENTIFIER'
      "4" # Text
    else
      "4" # Default to text
    end
  end
  
  def save_template_to_file(template)
    puts "Şablon dosyaya kaydediliyor: #{@output_file}" if @verbose
    
    File.open(@output_file, 'w') do |file|
      file.write(JSON.pretty_generate(template))
    end
    
    puts "Şablon başarıyla kaydedildi: #{@output_file}" if @verbose
  end
end

# Komut satırı argümanlarını işle
options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Kullanım: ruby mib2zabbix_simple.rb [seçenekler] <mib_dosyası>"
  
  opts.on("-o", "--output FILE", "Çıktı dosyası") do |file|
    options[:output_file] = file
  end
  
  opts.on("-t", "--template-name NAME", "Şablon adı") do |name|
    options[:template_name] = name
  end
  
  opts.on("-g", "--group GROUP", "Şablon grup adı (birden fazla grup için virgülle ayırın)") do |group|
    options[:groups] = group.split(',').map(&:strip)
  end
  
  opts.on("-v", "--verbose", "Ayrıntılı çıktı") do
    options[:verbose] = true
  end
  
  opts.on("-h", "--help", "Yardım") do
    puts opts
    exit
  end
end

parser.parse!

if ARGV.empty?
  puts parser
  exit 1
end

options[:mib_file] = ARGV[0]

converter = MIB2Zabbix.new(options)
converter.run