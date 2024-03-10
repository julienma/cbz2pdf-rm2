# Convert CBZ to PDF optimized for reMarkable 2

## Prereqs

```
# Install ruby version from .tool-versions, using asdf
asdf install

# Install gems
bundle install
```

## Convert

To convert a single file:

```sh
bundle exec ruby cbz2pdf.rb input_file.cbz -o output_file.pdf
```

To convert all *.cbz in current directory (with ZSH):

```sh
for f in *.cbz; do bundle exec ruby cbz2pdf.rb "$f" -o "$f.pdf"; done
```
