// g++ -std=c++17 -g main.cc -larchive
#include <iostream>
#include <string>
#include <string_view>
#include <filesystem>
#include <ctime>
#include <fstream>
#include <CLI/CLI.hpp>
#include <archive.h>
#include <archive_entry.h>

inline constexpr std::string_view output_hbar =
  "--------------------------------------------------------------------------------";

bool ignore_interval = false;
bool debug = false;

std::string get_current_date();
bool make_tar (const std::filesystem::path& directory,
               const std::filesystem::path& archive_path);

int main (int argc, char** argv)
{
  CLI::App app {
    "Small app to back up a directory into a dated tar archive."
  };
  app.set_version_flag("-v, --version", "1.0.0");

  std::filesystem::path target_directory;
  std::filesystem::path destination_directory;

  app.add_option("-t,--target-directory",
                 target_directory,
                 "directory to back up")
    ->required()
    ->check(CLI::ExistingDirectory);
  app.add_option("-d,--destination-directory",
                 destination_directory,
                 "directory that will store the backup")
    ->required()
    ->check(CLI::ExistingDirectory);
  app.add_flag("-i,--ignore-interval",
               ignore_interval,
               "ignore the interval between two backups");
  app.add_flag("-D,--debug",
               debug,
               "print more information to the output");

  CLI11_PARSE(app, argc, argv);

  if (debug) {
    std::cout << std::boolalpha;
    std::cout << output_hbar << '\n';
    std::cout << "app arguments:" << '\n';
    std::cout << "target directory: " << target_directory.string() << '\n';
    std::cout << "destination directory: " << destination_directory.string() << '\n';
    std::cout << "ignore interval: " << ignore_interval << '\n';
    std::cout << "debug: " << debug << '\n';
    std::cout << output_hbar << '\n';
  }

  std::string current_date = get_current_date();
  if (debug) {
    std::cout << output_hbar << '\n';
    std::cout << "current date " << current_date << '\n';
    std::cout << output_hbar << '\n';
  }

  std::filesystem::path result_archive_path =
    destination_directory / (current_date + ".tar");
  if (debug) {
    std::cout << output_hbar << '\n';
    std::cout << "result archive path: " << result_archive_path.string() << '\n';
    std::cout << output_hbar << '\n';
  }

  return make_tar(target_directory, result_archive_path);
}

std::string
get_current_date ()
{
  char result[11];

  std::time_t now = std::time(nullptr);
  std::tm* local_tm = std::localtime(&now);
  if (local_tm == nullptr) return {};
  if (std::strftime(result, sizeof result, "%Y-%m-%d", local_tm) == 0) return {};

  return result;
}

bool
make_tar (const std::filesystem::path& directory,
          const std::filesystem::path& archive_path)
{
  archive* out = archive_write_new();
  archive* disk = archive_read_disk_new();
  archive_write_set_format_pax_restricted(out);

  bool ok =
    archive_write_open_filename(out, archive_path.string().c_str()) == ARCHIVE_OK;
  if (!ok) std::cerr << archive_error_string(out) << '\n';

  std::error_code error_code;
  std::filesystem::recursive_directory_iterator iterator(directory, error_code);
  std::filesystem::recursive_directory_iterator end;

  for (; ok && iterator != end; iterator.increment(error_code)) {
    // check that we are not trying to archive directory
    // where the archive will be stored
    std::error_code equivalent_error_code;
    if (std::filesystem::equivalent(iterator->path(),
                                    archive_path,
                                    equivalent_error_code)) {
      continue;
    }

    archive_entry* entry = archive_entry_new();
    archive_entry_copy_sourcepath(entry, iterator->path().string().c_str());
    archive_entry_set_pathname(entry,
                               std::filesystem::relative(iterator->path(),directory).generic_string().c_str());
    if (archive_read_disk_entry_from_file(disk, entry, -1, nullptr) < ARCHIVE_WARN) {
      std::cerr << archive_error_string(disk) << '\n';
      archive_entry_free(entry);
      ok = false;
      break;
    }

    // check the file can be opened
    std::ifstream in;
    if (archive_entry_filetype(entry) == AE_IFREG) {
      in.open(iterator->path(), std::ios::binary);
      if (!in) {
        std::cerr << "cannot open " << iterator->path() << '\n';
        archive_entry_free(entry);
        ok = false;
        break;
      }
    }

    if (archive_write_header(out, entry) != ARCHIVE_OK) {
      std::cerr << archive_error_string(out) << '\n';
      ok = false;
    } else {
      std::cout << "added: " << archive_entry_pathname(entry) << '\n';
      if (archive_entry_filetype(entry) == AE_IFREG) {
        char buffer[8192];
        while(ok && (in.read(buffer, sizeof buffer) || in.gcount() >0)) {
          if (archive_write_data(out,
                                 buffer,
                                 static_cast<size_t>(in.gcount())) < 0) {
            std::cerr << archive_error_string(out) << '\n';
            ok = false;
          }
        }
      }
    }
    archive_entry_free(entry);
  }
  if (error_code) {
    std::cerr << error_code.message() << '\n';
    ok = false;
  }

  archive_read_free(disk);
  if (archive_write_close(out) != ARCHIVE_OK) ok = false;
  archive_write_free(out);

  return ok;
}
