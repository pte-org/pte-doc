# Question media fixtures

Local copies of the media used by the question-authoring demo are kept in this
folder so future question creation can select files from the repository instead
of relying on an ad-hoc temporary path.

## Contents

- `source-repeat_sentence_sample.wav` — source audio used for Repeat Sentence.
- `source-mc_listening_single_sample.wav` — source audio already present in the
  local fixture set.
- `source-describe_image_sample.png` — source image used for Describe Image.
- `audio-<media-public-id>.wav` — audio assets downloaded from Cloudinary.
- `image-<media-public-id>.png` — image assets downloaded from Cloudinary.

The Cloudinary snapshot currently contains 27 audio files and 2 image files
from `pte/local/question-media`. The UUID in each downloaded filename is the
media public ID, so it can be matched with a question's `audioPromptRef` or
`imagePromptRef`. The larger `audio-397ab69b-478d-4e8f-ba5a-a16e3de097fa.wav`
file is retained because it was already present in Cloudinary before the
question-authoring run.

When creating another question, use the `source-*` files for a simple reusable
fixture, or select the corresponding `audio-*`/`image-*` asset when reproducing
an existing question. Upload still happens through the Vendor Question Bank UI;
this folder is only the local media archive and does not replace the Cloudinary
media record.
