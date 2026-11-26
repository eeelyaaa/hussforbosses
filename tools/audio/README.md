# tools/audio (M1-04)
Run with the ro-team venv: `C:/Users/elya/Desktop/ro-team/.venv-audio/Scripts/python.exe tools/audio/<script> ...` (numpy + ffmpeg on PATH).
- `measure.py FILE...`  length, peak and where, RMS, LUFS (0.4 s or longer; shorter files read -70), lead silence, hard tail.
- `probe.py FILE`       envelope probe: the loud parts (huss bursts), peak and onset at 10/20/30 dB under, against the brief's BEAT.
- `cut.py IN OUT --start --end --fade-in --fade-out`   trim and fade (ffmpeg).
- `level.py IN OUT --peak -1.0 | --lufs X`             gain only.
- `standin_spec.json`   the earshot spec the stand-in set came from (`earshot make --spec standin_spec.json -o out`); the shipped files are takes of thump/book (thuds), flick/thin (swish), tick/glass cut to 0.40 s (sting).
The in-Studio probe on the uploaded asset is M1-13 (`studio/checks/Probe.lua`); `probe.py` is the same maths on the local file.
