from openai import OpenAI
import json
import os

langs = {
    "ar": "Arabic",
    "ca": "Catalan",
    "zh-Hans": "Chinese (Simplified)",
    "zh-Hant": "Chinese (Traditional)",
    "hr": "Croatian",
    "cs": "Czech",
    "da": "Danish",
    "nl": "Dutch",
    "en": "English",
    "en-AU": "English (Australia)",
    "en-CA": "English (Canada)",
    "en-GB": "English (U.K.)",
    "en-US": "English (U.S.)",
    "fi": "Finnish",
    "fr": "French",
    "fr-CA": "French (Canada)",
    "de": "German",
    "el": "Greek",
    "he": "Hebrew",
    "hi": "Hindi",
    "hu": "Hungarian",
    "id": "Indonesian",
    "it": "Italian",
    "ja": "Japanese",
    "ko": "Korean",
    "ms": "Malay",
    "no": "Norwegian",
    "pl": "Polish",
    "pt-BR": "Portuguese (Brazil)",
    "pt-PT": "Portuguese (Portugal)",
    "ro": "Romanian",
    "ru": "Russian",
    "sk": "Slovak",
    "es-MX": "Spanish (Mexico)",
    "es": "Spanish (Spain)",
    "sv": "Swedish",
    "th": "Thai",
    "tr": "Turkish",
    "uk": "Ukrainian",
    "vi": "Vietnamese",
}

# Prompt the user for necessary information
api_key = os.environ['OPENAI_API_KEY']
target_languages_input = ", ".join(list(langs.keys()))
model = 'gpt-4'
description = 'timelapse is an app for creating screen and camera timelapses'
input_file = 'InfoPlist.xcstrings'
output_file = 'out.xcstrings'
state = 'translated'

# Process the target languages input
target_languages = [lang.strip() for lang in target_languages_input.split(",")]

# Set the OpenAI API key
client = OpenAI(api_key=api_key)

def read_string_catalog(path):
    """Reads a string catalog from a JSON file."""
    with open(path, 'r', encoding='utf-8') as f:
        string_data = f.read()
    return json.loads(string_data)

def write_string_catalog(path, catalog):
    """Writes the string catalog to a JSON file with specific formatting."""
    json_string = json.dumps(catalog, indent=2, ensure_ascii=False)
    formatted_json = "\n".join([
        line.replace(": ", " : ").replace("{}", "{\n\n    }")
        for line in json_string.split("\n")
    ]) + "\n"
    with open(path, 'w', encoding='utf-8') as f:
        f.write(formatted_json)

def get_completion(string, comment, source_language, target_languages, description):
    """Calls the OpenAI API to translate a string into multiple languages."""
    language_names = [langs.get(lang, lang) + f" ({lang})" for lang in target_languages]
    language_names_str = ', '.join(language_names)
    comment_str = f"A comment from the developer: {comment}" if comment else ""
    description_str = f"The project description is: {description}" if description else ""

    system_prompt = (
        f"You are a translation expert proficient in translating from {source_language} to the following languages: "
        f"{language_names_str}. {description_str} You are asked to translate the following string "
        f"and return the result in a JSON object with the language code as the key and the translation "
        f"as the value. Do not modify template strings (e.g., %lld) in any way. {comment_str}"
    )

    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": string}
    ]

    response = client.chat.completions.create(
        model=model,
        messages=messages,
        temperature=0.0
    )

    completion = response.choices[0].message.content

    # Try to parse the completion as JSON
    try:
        translation = json.loads(completion)
    except json.JSONDecodeError:
        print(f"Failed to parse the assistant's response as JSON for string '{string}'.")
        translation = {}
    return translation

def multi_translate(key, strings, target_languages, source_language, description):
    """Translates a single string into multiple languages."""
    comment = strings[key].get('comment', '')
    print(f"Translating '{key}'...")

    # Skip keys that should not be translated
    keys_to_skip = ['NSBundleDisplayName']
    if key in keys_to_skip:
        print(f"Skipping translation for key '{key}'.")
        return {}

    # Get the English localization
    english_value = None
    if 'localizations' in strings[key]:
        en_locale = strings[key]['localizations'].get('en', {})
        if 'stringUnit' in en_locale and 'value' in en_locale['stringUnit']:
            english_value = en_locale['stringUnit']['value']

    if not english_value:
        print(f"No English localization found for key '{key}'. Skipping translation.")
        return {}

    translation = get_completion(
        string=english_value,
        comment=comment,
        source_language=source_language,
        target_languages=target_languages,
        description=description
    )

    # Build the localizations object
    localizations = {}
    for lang in translation:
        localizations[lang] = {
            "stringUnit": {
                "value": translation[lang],
                "state": state
            }
        }
    return localizations

def translate():
    """Main function to translate the string catalog."""
    string_catalog = read_string_catalog(input_file)
    source_language = string_catalog['sourceLanguage']
    strings = string_catalog['strings']

    new_strings = {}
    for key in strings:
        localizations = multi_translate(
            key,
            strings,
            target_languages,
            source_language,
            description
        )
        comment = strings[key].get('comment', '')
        # Merge existing localizations with new translations
        existing_localizations = strings[key].get('localizations', {})
        existing_localizations.update(localizations)
        new_strings[key] = {
            "comment": comment,
            "localizations": existing_localizations
        }

    new_string_catalog = {
        "sourceLanguage": source_language,
        "strings": new_strings,
        "version": string_catalog.get('version', '1.0')
    }

    write_string_catalog(output_file, new_string_catalog)
    print(f"Translation completed. Output saved to '{output_file}'.")

if __name__ == "__main__":
    translate()
