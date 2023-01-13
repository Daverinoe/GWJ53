class_name IOHelper


# Private constants

const OUTPUT_RELATIVE: String = "user://"


# Public methods

static func directory_create(path: String, relative: bool = true) -> bool:
	var normalized_path: String = normalize_path(path, relative)

	var result: int = DirAccess.make_dir_recursive_absolute(normalized_path)
	if result != OK:
		# TODO: Add logger
		return false

	return true


static func directory_exists(path: String, relative: bool = true) -> bool:
	var normalized_path: String = normalize_path(path, relative)

	var directory = DirAccess.open(OUTPUT_RELATIVE)

	return directory.dir_exists(normalized_path)


static func directory_list_files(path: String, relative: bool = true) -> PackedStringArray:
	var normalized_path: String = normalize_path(path, relative)

	var directory = DirAccess.open(OUTPUT_RELATIVE)

	if !directory.dir_exists(normalized_path):
		return PackedStringArray([])

	directory = DirAccess.open(normalized_path)
	if DirAccess.get_open_error() != OK:
		# TODO: Add logger

		return PackedStringArray([])

	return directory.get_files()


static func file_delete(path: String, relative: bool = true) -> bool:
	var normalized_path: String = normalize_path(path, relative)

	var directory = DirAccess.open(OUTPUT_RELATIVE)

	var result: int = directory.remove(normalized_path)
	if result != OK:
		# TODO: Add logger

		return false

	return true


static func file_exists(path: String, relative: bool = true) -> bool:
	var normalized_path: String = normalize_path(path, relative)

	return FileAccess.file_exists(normalized_path)


static func file_load(path: String, relative: bool = true) -> String:
	var normalized_path: String = normalize_path(path, relative)

	var result: FileAccess = FileAccess.open(normalized_path, FileAccess.READ)
	if FileAccess.get_open_error() != OK:
		# TODO: Add logger

		return ""

	var content: String = result.get_as_text()

	return content


static func file_save(content: String, path: String, relative: bool = true) -> bool:
	var normalized_path: String = normalize_path(path, relative)

	var result: FileAccess = FileAccess.open(normalized_path, FileAccess.WRITE)
	if FileAccess.get_open_error() != OK:
		push_warning("File failed to save! Path3D: %s" % normalized_path)

		return false

	result.store_string(content)

	return true


# Private methods

static func normalize_path(path: String, relative: bool) -> String:
	if relative:
		return OUTPUT_RELATIVE + path

	return path
