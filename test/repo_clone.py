from twobit.oebuild import Repo

def main():
    """ Test case to exercise the twobit.oebuild.Repo object.

    This requires a pile of setup. Document that here. Do said setup in a
    supporting script.
    """
    repo = Repo("repo_clone_test",
                "repo_clone.git",
                "master",
                "head",
                None)
    print("twobit.oebuild.Repo test Clone:\n{0}".format (repo))
    try:
        repo.clone("./repo_clone_test")
    except Error as e:
        print(e)
        sys.exit(1)

if __name__ == '__main__':
    main()
