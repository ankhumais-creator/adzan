import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/app_settings.dart';

/// Settings page for app configuration
class SettingsPage extends StatefulWidget {
  final AppSettings settings;

  const SettingsPage({super.key, required this.settings});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = AppSettings(
      calculationMethod: widget.settings.calculationMethod,
      madhab: widget.settings.madhab,
      adzanSoundEnabled: widget.settings.adzanSoundEnabled,
      vibrationEnabled: widget.settings.vibrationEnabled,
      notificationEnabled: widget.settings.notificationEnabled,
      adzanVolume: widget.settings.adzanVolume,
      useManualLocation: widget.settings.useManualLocation,
      manualLatitude: widget.settings.manualLatitude,
      manualLongitude: widget.settings.manualLongitude,
      manualLocationName: widget.settings.manualLocationName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'PENGATURAN',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            letterSpacing: 4,
            fontWeight: FontWeight.w300,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _settings),
            child: Text(
              'SIMPAN',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Calculation Method Section
          _buildSectionTitle('METODE PERHITUNGAN'),
          const SizedBox(height: 12),
          _buildDropdownCard(
            value: _settings.calculationMethod,
            items: AppSettings.calculationMethods,
            onChanged: (value) {
              setState(() => _settings.calculationMethod = value!);
            },
          ),

          const SizedBox(height: 24),

          // Madhab Section
          _buildSectionTitle('MADHAB'),
          const SizedBox(height: 12),
          _buildDropdownCard(
            value: _settings.madhab,
            items: AppSettings.madhabs,
            onChanged: (value) {
              setState(() => _settings.madhab = value!);
            },
          ),

          const SizedBox(height: 24),

          // Sound & Vibration Section
          _buildSectionTitle('SUARA & GETAR'),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildSwitchTile(
              icon: Icons.volume_up_rounded,
              title: 'Suara Adzan',
              subtitle: 'Putar suara adzan saat waktu sholat',
              value: _settings.adzanSoundEnabled,
              onChanged: (value) {
                setState(() => _settings.adzanSoundEnabled = value);
              },
            ),
            if (_settings.adzanSoundEnabled) ...[
              const Divider(color: Colors.white12, height: 1),
              _buildSliderTile(
                icon: Icons.tune_rounded,
                title: 'Volume Adzan',
                value: _settings.adzanVolume.toDouble(),
                onChanged: (value) {
                  setState(() => _settings.adzanVolume = value.round());
                },
              ),
            ],
            const Divider(color: Colors.white12, height: 1),
            _buildSwitchTile(
              icon: Icons.vibration_rounded,
              title: 'Getar',
              subtitle: 'Aktifkan getar saat adzan dan tasbih',
              value: _settings.vibrationEnabled,
              onChanged: (value) {
                setState(() => _settings.vibrationEnabled = value);
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Notification Section
          _buildSectionTitle('NOTIFIKASI'),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildSwitchTile(
              icon: Icons.notifications_rounded,
              title: 'Notifikasi Waktu Sholat',
              subtitle: 'Tampilkan notifikasi saat waktu sholat',
              value: _settings.notificationEnabled,
              onChanged: (value) {
                setState(() => _settings.notificationEnabled = value);
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Location Section
          _buildSectionTitle('LOKASI'),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildSwitchTile(
              icon: Icons.location_on_rounded,
              title: 'Lokasi Manual',
              subtitle: 'Gunakan lokasi yang dipilih, bukan GPS',
              value: _settings.useManualLocation,
              onChanged: (value) {
                setState(() => _settings.useManualLocation = value);
              },
            ),
            if (_settings.useManualLocation) ...[
              const Divider(color: Colors.white12, height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lokasi Saat Ini',
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _settings.manualLocationName,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_settings.manualLatitude.toStringAsFixed(4)}, ${_settings.manualLongitude.toStringAsFixed(4)}',
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showLocationSearchDialog(context),
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('CARI LOKASI'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white12,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ]),

          const SizedBox(height: 32),

          // Support Section
          _buildSectionTitle('DUKUNG PENGEMBANG'),
          const SizedBox(height: 12),
          _buildSettingsCard([
            ListTile(
              onTap: () async {
                final uri = Uri.parse('https://saweria.co/ankhumais');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.favorite_outline, color: Colors.redAccent, size: 20),
              ),
              title: Text(
                'Berikan Hadiah',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              ),
              subtitle: Text(
                'Bantu pengembangan aplikasi ini',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
              ),
              trailing: const Icon(Icons.open_in_new, color: Colors.white38, size: 18),
            ),
          ]),

          const SizedBox(height: 32),

          // About Section
          _buildSectionTitle('TENTANG'),
          const SizedBox(height: 12),
          _buildSettingsCard([
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info_outline, color: Colors.white54, size: 20),
              ),
              title: Text(
                'Adzan Monokrom',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              ),
              subtitle: Text(
                'Versi 1.0.0',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        color: Colors.white38,
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildDropdownCard({
    required String value,
    required List<Map<String, String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1a1a1a),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white38),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item['id'],
              child: Text(item['name']!),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white54, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.white38;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white38;
          }
          return Colors.white12;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    required double value,
    required void Function(double) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white54, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                    ),
                    Text(
                      '${value.round()}%',
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.white,
                    overlayColor: Colors.white24,
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: value,
                    min: 0,
                    max: 100,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationSearchDialog(BuildContext context) {
    final searchController = TextEditingController();
    List<Location> searchResults = [];
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF121212),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'CARI LOKASI',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w300,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ketik nama kota...',
                        hintStyle: GoogleFonts.inter(color: Colors.white38),
                        prefixIcon: const Icon(Icons.search, color: Colors.white38),
                        suffixIcon: isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white38,
                                  ),
                                ),
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white.withAlpha(10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (value) async {
                        if (value.trim().isEmpty) return;
                        setDialogState(() => isSearching = true);
                        try {
                          final locations = await locationFromAddress(value);
                          setDialogState(() {
                            searchResults = locations;
                            isSearching = false;
                          });
                        } catch (e) {
                          setDialogState(() {
                            searchResults = [];
                            isSearching = false;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    if (searchResults.isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final loc = searchResults[index];
                            return FutureBuilder<List<Placemark>>(
                              future: placemarkFromCoordinates(loc.latitude, loc.longitude),
                              builder: (context, snapshot) {
                                String locationName = '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}';
                                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                  final place = snapshot.data!.first;
                                  locationName = '${place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? 'Unknown'}, ${place.country ?? ''}';
                                }
                                return ListTile(
                                  leading: const Icon(Icons.location_on, color: Colors.white54),
                                  title: Text(
                                    locationName,
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}',
                                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _settings.manualLatitude = loc.latitude;
                                      _settings.manualLongitude = loc.longitude;
                                      _settings.manualLocationName = locationName;
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    if (searchResults.isEmpty && !isSearching)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Ketik nama kota dan tekan Enter untuk mencari',
                          style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'BATAL',
                    style: GoogleFonts.inter(color: Colors.white54),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
