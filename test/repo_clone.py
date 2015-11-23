from twobit.oebuild import Repo
from argparse import ArgumentParser
import sys

def main():
    """ Test case to exercise the clone function from the twobit.oebuild.Repo object.
    """
    description="Program to clone git repo using the twobit.oebuild.Repo object."
    parser = ArgumentParser(prog=__file__, description=description)
    parser.add_argument("-n", "--name",
                        default="repo_clone_test",
                        help="name of Repo object")
    parser.add_argument("-u", "--url",
                        default="repo_clone.git",
                        help="URL of repo")
    parser.add_argument("-b", "--branch",
                        default="master",
                        help="default branch")
    parser.add_argument("-r", "--revision",
                        default="head",
                        help="default revision")
    args = parser.parse_args()

    repo = Repo(args.name, args.url, args.branch, args.revision, None)
    print("twobit.oebuild.Repo test Clone:\n{0}".format (repo))
    try:
        repo.clone(args.name)
    except Exception as e:
        print(e)
        sys.exit(1)

if __name__ == '__main__':
    main()
