#!/bin/sh
# The demo video (demo/out/pixalorien_demo.mp4, 1920x1080, 30 a second,
# under three minutes) from the recorded pictures (demo/frames/: ad.ent,
# tutor.ent, play.ent) and the art, with captions in the game's fonts
# and colours, and "Mist City" under it. Clips are made one by one in
# demo/out/clips/, then joined. Run from the repository's root:
#   demo/make_video.sh
set -eu
[ -f demo/make_video.sh ] || cd "$(dirname "$0")/.."
OUT=demo/out
C=$OUT/clips
mkdir -p "$C"
HEAD=fonts/Silkscreen-Bold.ttf
BODY=fonts/m5x7.ttf
AMBER=0xffc040
INK=0xe8d4b0
PANEL=0x1c1412
FPS=30
ENC="-c:v libx264 -crf 16 -preset medium -pix_fmt yuv420p -r $FPS"

# A caption: a heading and a line under it, bottom left, in from `a` to
# `b` seconds (faded), as a filter string. Text goes through files (one
# each, as a caption is made in a subshell), so no escaping.
caption() { # heading body a b [y]
  n=$(mktemp -u XXXXXX)
  printf '%s' "$1" > "$C/h$n.txt"
  printf '%s' "$2" > "$C/b$n.txt"
  y=${5:-820}
  al="if(lt(t,$3),0,if(lt(t,$3+0.4),(t-$3)/0.4,if(lt(t,$4-0.4),1,if(lt(t,$4),($4-t)/0.4,0))))"
  printf "drawbox=x=60:y=%s:w=1260:h=150:color=%s@0.88:t=fill:enable='between(t,%s,%s)'," "$y" "$PANEL" "$3" "$4"
  printf "drawbox=x=60:y=%s:w=6:h=150:color=%s:t=fill:enable='between(t,%s,%s)'," "$y" "$AMBER" "$3" "$4"
  printf "drawtext=fontfile=%s:textfile=%s:x=96:y=%s+28:fontsize=34:fontcolor=%s:alpha='%s'," "$HEAD" "$C/h$n.txt" "$y" "$AMBER" "$al"
  printf "drawtext=fontfile=%s:textfile=%s:x=96:y=%s+78:fontsize=48:fontcolor=%s:alpha='%s'" "$BODY" "$C/b$n.txt" "$y" "$INK" "$al"
}

# A clip of recorded pictures: from picture `from`, `count` of them,
# played `speed` times as fast (2 shows every second one), with filters
# (captions) after. The pictures are PNG or QOI, as recorded.
pictures() { # dir from count speed out [filters]
  f=${6:-null}
  ext=$(ls "demo/frames/$1" | head -1 | sed 's/.*\.//')
  rate=$(echo "$FPS * $4" | bc -l)
  dur=$(echo "$3 / $rate" | bc -l)
  ffmpeg -v error -y -framerate "$rate" -start_number "$2" -i "demo/frames/$1/f%06d.$ext" \
    -vf "trim=end_frame=$3,setpts=PTS-STARTPTS,scale=1920:1080:flags=lanczos,fps=$FPS,$f,fade=t=in:st=0:d=0.3,fade=t=out:st=$(echo "$dur - 0.3" | bc -l):d=0.3" \
    $ENC "$C/$5.mp4"
}

# A still, slowly nearer, for `dur` seconds, on the panel's colour.
still() { # image dur out [filters]
  f=${4:-null}
  frames=$(( $2 * FPS ))
  ffmpeg -v error -y -loop 1 -i "$1" -frames:v "$frames" \
    -vf "scale=3840:2160:force_original_aspect_ratio=decrease:flags=lanczos,pad=3840:2160:(ow-iw)/2:(oh-ih)/2:color=$PANEL,zoompan=z='1+0.06*on/$frames':x='iw/2-iw/zoom/2':y='ih/2-ih/zoom/2':d=1:s=1920x1080:fps=$FPS,$f,fade=t=in:st=0:d=0.4,fade=t=out:st=$(echo "$2 - 0.4" | bc -l):d=0.4" \
    $ENC "$C/$3.mp4"
}

# A picture smaller, at the top (the room under it for a caption), a
# little nearer as it goes.
framed() { # image dur out [filters]
  f=${4:-null}
  frames=$(( $2 * FPS ))
  ffmpeg -v error -y -loop 1 -i "$1" -frames:v "$frames" \
    -vf "scale=3000:-1:flags=neighbor,pad=3840:2160:(ow-iw)/2:40:color=$PANEL,zoompan=z='1+0.03*on/$frames':x='iw/2-iw/zoom/2':y='0':d=1:s=1920x1080:fps=$FPS,$f,fade=t=in:st=0:d=0.4,fade=t=out:st=$(echo "$2 - 0.4" | bc -l):d=0.4" \
    $ENC "$C/$3.mp4"
}

# A card of text alone, on the panel's colour.
card() { # dur out heading line1 line2 line3
  n=$(mktemp -u XXXXXX)
  printf '%s' "$3" > "$C/h$n.txt"
  printf '%s\n%s\n%s' "$4" "$5" "$6" > "$C/b$n.txt"
  ffmpeg -v error -y -f lavfi -i "color=c=$PANEL:s=1920x1080:r=$FPS:d=$1" \
    -vf "drawtext=fontfile=$HEAD:textfile=$C/h$n.txt:x=(w-tw)/2:y=330:fontsize=64:fontcolor=$AMBER,drawtext=fontfile=$BODY:textfile=$C/b$n.txt:x=(w-tw)/2:y=480:fontsize=60:line_spacing=22:fontcolor=$INK,fade=t=in:st=0:d=0.4,fade=t=out:st=$(echo "$1 - 0.4" | bc -l):d=0.4" \
    $ENC "$C/$2.mp4"
}

# Run on its own, the whole film; sourced (for trying a helper), nothing.
[ "${0##*/}" = make_video.sh ] || return 0 2>/dev/null || exit 0
rm -f "$C"/*.mp4 "$C"/*.txt

# 1. The title screen, and the advert the game films of itself.
pictures ad 0 150 1 01_title "$(caption 'A FALLING-SAND EXPEDITION' 'Three soldiers, one treasure, and a planet where every grain falls' 0.6 4.9)"
pictures ad 150 1200 1 02_advert "$(caption 'THE GAME FILMS ITS OWN ADVERT' 'Water, ice, creatures, crumbling rock, magma: all of it simulated' 0.8 7.4 130),$(caption 'THE RECRUITER' 'Her portrait made with Meta Muse Image, cut into a talk cycle' 8.6 15.4 130)"

# 2. The tutorial, the sergeant's lessons (lessons 1 to 14 nearer:
# tutor8; 15 on as the game is: tutor4).
pictures tutor8 45 285 2 03_walk "$(caption 'REAL TIME WITH PAUSE' 'Point and order: each one finds its own way over what it has seen' 0.5 4.5 560)"
pictures tutor8 1090 272 2 04_grapple "$(caption 'GRAPPLE, LADDERS, JETPACK' 'A hook holds on rock and wood; on glass they fly' 0.4 8.0 560)"
pictures tutor8 1362 318 2 05_jet
pictures tutor8 1680 182 1.5 06_torch "$(caption 'TORCH AND CHARGE' 'Cut a door or blow one: the rock falls where it falls' 0.4 9.0 560)"
pictures tutor8 1862 353 2 07_charge
pictures tutor4 0 319 2 08_back "$(caption 'GOING BACK' 'Set your own squad on fire? Back five seconds, and do it right' 0.4 5.0 560)"
pictures tutor4 380 217 1.5 09_scan "$(caption 'THE SCANNER' 'See through the hill before you cut into it' 0.4 4.4 560)"
pictures tutor4 612 420 1.5 10_roof "$(caption 'THE PLANET FIGHTS BACK' 'A charge brings the cave roof down...' 0.4 4.0 560),$(caption 'UNDO ANYTHING' '...so drag the timeline back to before the bang' 4.3 9.0 560)"
pictures tutor4 1032 265 2.5 11_chest
pictures tutor4 1297 1822 6 12_home "$(caption 'THE AUTOPILOT' 'Cautious or brute force: it digs its own way to the vault and home' 0.4 9.8 560)"

# 3. An expedition on a world of its own: the start, the end, the
# results.
pictures play 0 435 2 13_start "$(caption 'EVERY WORLD FROM A SEED' '2048 by 1024 cells, simulated on all cores' 0.5 7.0 620)"
pictures play 435 525 2 14_end "$(caption 'BRUTE FORCE, FOUR TIMES THE SPEED' 'The tech carries the chest up 216 metres of its own tunnel' 0.5 8.5 620)"
pictures play 960 187 1 15_results "$(caption 'ALL THREE HOME' "The results: the dig, each one's fate, the counts" 0.4 6.0 860)"

# 4. The run as a picture; how it was made; the end.
framed demo/card.png 7 16_card "$(caption 'A RUN IN A PICTURE' 'Post it anywhere. Drop it on the game: it plays again, checked as it goes' 0.5 6.7 905)"
still art/round1/marketing-art.png 3 17_art1 "$(caption 'ART DIRECTION: META MUSE IMAGE 1.0' 'Three rounds of key art, from the first brief...' 0.3 3.0 860)"
still art/round2/marketing-art.png 2 18_art2 "$(caption 'ART DIRECTION: META MUSE IMAGE 1.0' 'Three rounds of key art, from the first brief...' 0 2.0 860)"
still art/round3/marketing-art.png 3 19_art3 "$(caption 'ART DIRECTION: META MUSE IMAGE 1.0' '...to the title screen' 0 2.8 860)"
still art/round1/characters.png 3 20_chars "$(caption 'THE SQUAD' 'Character sheets from Muse Image; the sprites drawn by hand from them' 0.3 5.8 860)"
still art/sprites_x8.png 3 21_sprites "$(caption 'THE SQUAD' 'Character sheets from Muse Image; the sprites drawn by hand from them' 0 2.8 860)"
still art/round3/sergeant-talk.png 4 22_talk "$(caption 'THE SERGEANT AND THE RECRUITER' 'Muse Image portraits, cut into six-frame talk cycles' 0.3 3.8 860)"
card 6 23_code "MADE WITH" "Muse Code (Muse Wonder 1.0) and Claude Code" "in ent: a data-oriented language" "the same world on every core and every OS, bit for bit"
still art/round3/marketing-art.png 6 24_outro "drawbox=x=0:y=820:w=1920:h=260:color=$PANEL@0.9:t=fill,drawtext=fontfile=$HEAD:text='PIXALORIEN':x=(w-tw)/2:y=850:fontsize=64:fontcolor=$AMBER,drawtext=fontfile=$BODY:text='by Maxim Zaks  -  Meta Global AI Developer Hackathon':x=(w-tw)/2:y=950:fontsize=48:fontcolor=$INK,drawtext=fontfile=$BODY:text='Music\: Mist City by Section7 (CC BY 4.0)':x=(w-tw)/2:y=1010:fontsize=36:fontcolor=0x8a7660"

# Joined, the music under it (faded out at the end).
ls "$C"/[0-9]*.mp4 | sort | sed "s|^$C/|file '|; s|\$|'|" > "$C/list.txt"
ffmpeg -v error -y -f concat -safe 0 -i "$C/list.txt" -c copy "$OUT/film.mp4"
len=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT/film.mp4")
ffmpeg -v error -y -i "$OUT/film.mp4" -i music/mist_city.ogg -filter_complex "[1:a]atrim=0:$len,afade=t=in:d=0.5,afade=t=out:st=$(echo "$len - 3" | bc -l):d=3,volume=0.9[a]" \
  -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 192k -shortest "$OUT/pixalorien_demo.mp4"
echo "$OUT/pixalorien_demo.mp4: $len s"
