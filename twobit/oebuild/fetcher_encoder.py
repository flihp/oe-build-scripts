from json import JSONEncoder
from repo_fetcher import RepoFetcher

class FetcherEncoder(JSONEncoder):
    """ Encode RepoFetcher object as JSON

    Pass this class to the dumps function from the json module along with your
    RepoFetcher object.
    """
    def default(self, obj):
        """ Iterate over repo objects from RepoFetcher encoding each as JSON.
            Return the result in a list.

        obj: RepoFetcher that's being encoded as JSON.
        """
        if type(obj) is not RepoFetcher:
            raise TypeError
        if obj._repos is None:
            raise ValueError
        list_tmp = []
        for repo in obj._repos:
            list_tmp.append(RepoEncoder().default(repo))
        return list_tmp
