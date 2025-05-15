#!/bin/bash

VOICE="$(echo "${1}" | cut -d'/' -f1)"
SPEAKER="$(echo "${1}" | cut -s -d'/' -f2)"	# empty -> default speaker

[ ! -f /app/config/voice_to_speaker.yaml ] && cp /app/voice_to_speaker.default.yaml /app/config/voice_to_speaker.yaml

/app/download_voices_tts-1.sh "${VOICE}"

sed -i -e "/tts-1:/a\  ${VOICE}:\n    model: voices/${VOICE}.onnx\n    speaker: ${SPEAKER}" /app/config/voice_to_speaker.yaml
