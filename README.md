# MIB2Zabbix

A simple Ruby tool to convert MIB (Management Information Base) files to Zabbix templates. This tool automatically creates Zabbix templates for SNMP monitoring.

MIB2Zabbix parses MIB files and extracts OIDs, then generates Zabbix templates in JSON format that can be directly imported into Zabbix. This simplifies the process of setting up SNMP monitoring for network devices in Zabbix.

## Requirements

- Ruby 2.0 or higher
- Standard Ruby libraries (`optparse`, `fileutils`, `json`)

## Basic Usage

```bash
ruby mib2zabbix_simple.rb <mib_file> -o <output_file>
```

Example:

```bash
ruby mib2zabbix_simple.rb TPLINK-MIB.mib -o tplink_template.json
```

## Command Line Options

| Option | Description |
|--------|-------------|
| `-o, --output FILE` | Output file (if not specified, output is written to standard output) |
| `-t, --template-name NAME` | Template name (if not specified, MIB file name is used) |
| `-g, --group GROUP` | Template group name (separate multiple groups with commas) |
| `-v, --verbose` | Verbose output |
| `-h, --help` | Show help message |

## Examples

1. Basic usage:

```bash
ruby mib2zabbix_simple.rb TPLINK-MIB.mib -o tplink_template.json
```

2. With custom template name:

```bash
ruby mib2zabbix_simple.rb TPLINK-MIB.mib -o tplink_template.json -t "TP-Link Switch"
```

3. With custom group:

```bash
ruby mib2zabbix_simple.rb TPLINK-MIB.mib -o tplink_template.json -g "Templates/Network devices/TP-Link"
```

4. With multiple groups:

```bash
ruby mib2zabbix_simple.rb TPLINK-MIB.mib -o tplink_template.json -g "Templates/Network devices,Templates/SNMP devices"
```

## Importing Template to Zabbix

To import the generated JSON template to Zabbix:

1. Log in to the Zabbix web interface
2. Go to **Configuration** > **Templates**
3. Click on the **Import** button in the top right corner
4. Select the generated JSON file in the **Import file** field
5. Set import rules (default settings are usually sufficient)
6. Click on the **Import** button

## Limitations

- This tool uses a simple regex-based parsing and may not fully parse complex MIB structures
- OID paths are simplified as `.1.3.6.1.4.1.{oid_suffix}`. This may not be correct for some MIB files
- Not all MIB file formats may be supported

## Troubleshooting

1. **OIDs not found**: The MIB file format may not be standard. Enable verbose output with the `-v` option to monitor the parsing process.

2. **Generated template doesn't work in Zabbix**: The generated OID paths may not be correct. After importing the template, manually check and correct the OID paths of the items if necessary.

3. **File reading error**: Make sure the MIB file is in the correct path and you have read permissions.

## Future Improvements

- More advanced MIB parsing
- Creating correct OID paths
- Zabbix API integration
- Trigger support
- Graph support

## License

This project is licensed under the MIT License. For details, see the `LICENSE` file.

## Contributing

We welcome contributions! Please send a pull request or open an issue.

1. Fork the repo
2. Create a new branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push your branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Contact

For questions or suggestions, please open an issue or send an email.

---

This tool is created to make it easier to convert MIB files to Zabbix templates. If you have any questions or suggestions, please feel free to contact us. 