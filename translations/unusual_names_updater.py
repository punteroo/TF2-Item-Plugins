# Unusual Effects Name Parser
#  Reads tf_english.txt to extract Unusual Particle ID Names

import sys
import os.path
import re
import io

if __name__ == "__main__":
    if len(sys.argv) < 3 or sys.argv[1] != '-tf' or sys.argv[3] != '-out':
        print("Wrong Script Usage")
        print("Usage:")
        print(f'py "{sys.argv[0]}" -tf <path_to_tf_english> -out <output_file>')
        exit(0)

    tf, out = sys.argv[2], sys.argv[4]

    if not os.path.isfile(tf):
        print(f"ERROR: tf_english.txt was not found at {tf}.")
        exit(0)

    f, content = None, None
    try:
        f = io.open(tf, mode='r', encoding='utf16')
        content = f.read()
    except IOError:
        print("ERROR: Could not read tf_english.txt. Insufficient permissions?")
        exit(0)

    print("BE WARNED: This script's job is only to parse your tf_english.txt and look for particle names.")
    print("           If you want other languages, those will have to be added manually.")
    print()
    print("           Be sure that your output file's name is unusuals.phrases.txt (you can change it later too if it's not the case)")
    print("           If you already have an output file this script will overwrite it entirely.")
    print()

    if input("Are you sure you want to continue? (Y/n): ")[0] == 'Y':
        print("File found. Compiling RegEx...")
        
        finder = re.compile(r'(?:\"(?:Attrib_Particle([0-9]+))\"\t+\"(.+)\")', re.M)

        trans = """\"Phrases\"\n{\n"""

        print("Splitting attribute particles...")
        
        for particle in finder.findall(content):
            # id is index 0
            # name is index 1
            #
            # ONLY UNCOMMENT THE NEXT LINE IF YOU WANT THEM TO BE PRINTED OUT AS THEY'RE RED
            #
            # print(f"Written particle ID {particle[0]} with name \"{particle[1]}\"")
            if int(particle[0]) > 3 and int(particle[0]) < 701:
                trans += f'	"Cosmetic_Eff{particle[0]}"' + """\n	{\n		\"en\"		\"""" + particle[1] + "\"\n" + "	}\n"
        trans += "}"

        print("Done writing. Outputting file...")

        try:
            with io.open(out, mode='w', encoding='utf-8') as output:
                try:
                    output.write(trans)

                    print("Process finished! You're up to date :D")
                    print("REMEMBER: Be sure that your file name is \"unusuals.phrases.txt\"!")
                    print("REMEMBER: Output file must be placed in tf/sourcemod/translations at your server's installation!")
                except:
                    print("Error while writing output file. Permissions issue?")
                    exit(0)
        except:
            print(f"ERROR: No permission to write in {out}")
            exit(0)
