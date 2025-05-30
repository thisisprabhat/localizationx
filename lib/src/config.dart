/// All the config related to the localizationx will be handled on `localizationx.conf` file
class LocalizationConfig {
  String language;
  String region;

  LocalizationConfig({required this.language, required this.region});

  void displayConfig() {
    print('Language: $language, Region: $region');
  }
}
