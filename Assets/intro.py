import fnmatch
import os
from luaparser import ast


class Intro:
    __readMeFile = None

    __assetsPath = os.path.dirname(os.path.realpath(__file__))
    __rootPath = __assetsPath + "/.."
    __rmFilename = "README.md"
    __introductionFile = 'intro.md'
    __outroFile = 'outro.md'

    __pathCategories = [
        'Items Editing',
        'Navigation',
        'Toolbars',
        'Tracks Properties'
    ]

    def __init__(self):
        self.__readMeFile = open(self.__rootPath + "/" + self.__rmFilename, 'a')
        self.__readMeFile.truncate(0)

    def fill_readme(self):
        self.__fill_introduction()
        self.__fill_scripts()
        self.__fill_outro()
        self.__readMeFile.close()

    def __fill_introduction(self):
        with open(self.__assetsPath + "/" + self.__introductionFile) as f:
            self.__readMeFile.write(f.read() + "\n")

    def __fill_outro(self):
        with open(self.__assetsPath + "/" + self.__outroFile) as f:
            self.__readMeFile.write(f.read() + "\n")

    def __fill_scripts(self):
        self.__readMeFile.write("## List of scripts\n\n")

        for category in self.__pathCategories:
            for root, dirnames, filenames in os.walk(self.__rootPath + "/" + category):
                for filename in sorted(fnmatch.filter(filenames, '*.lua')):
                    with open(os.path.join(root, filename)) as f:
                        lua = ast.parse(f.read())

                        if lua.body.body[0].comments:
                            description = ""
                            about = ""
                            aboutStarted = False
                            isWip = False

                            for comment in lua.body.body[0].comments:
                                if comment.s.find("@wip") >= 0:
                                    isWip = True
                                    break
                                if comment.s.find("@description") >= 0:
                                    description = comment.s[comment.s.find("@description") + 12:].strip()
                                elif comment.s.find("@about") >= 0:
                                    aboutStarted = True
                                elif aboutStarted:
                                    if comment.s.find("@provides") >= 0 or comment.s.find("@changelog") >= 0:
                                        aboutStarted = False
                                    else:
                                        about += comment.s[2:].strip() + "\n"

                            if isWip is False and len(description) > 0:
                                self.__readMeFile.write("#### " + description + "\n\n")
                                self.__readMeFile.write(about + "\n")


intro = Intro()
intro.fill_readme()
