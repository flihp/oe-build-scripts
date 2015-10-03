import os

class PathSanity(dict):
    """ Sanity check and nomalize paths relative to a top_dir.
    """
    def __init__(self, top_dir):
        super(PathSanity, self).__init__(self)
        if os.path.isdir(top_dir):
            self._top_dir = os.path.abspath(os.path.realpath(top_dir))
        else:
            raise ValueError("top_dir parmater does not exist")
    def setitem_strict(self, name, value, exist=True):
        """ Add file or directory as sub item to top_dir specified in
            constructor.
        name: Key for retrieval.
        value: Value associated with key.
        exist: Wiether or not the entity must exist. Exception is thrown if
               this is True and the item does not exist.
        """
        tmp = os.path.realpath(os.path.join(self._top_dir, value))
        if exist and not os.path.exists(tmp):
            raise ValueError("{0} does not exist".format(tmp))
        if not exist and os.path.exists(tmp):
            raise ValueError("{0} already exists".format(tmp))
        self.__setitem__(name, tmp)
    def getitem_rel(self, name):
        """ Get path relative to top_dir from name.
        """
        return os.path.relpath(self.__getitem__(name), start=self._top_dir)
    def __setitem__(self, name, value):
        """ Set path associated with name.
        
        Raise value error if path is not a subpath of top_dir.
        """
        tmp = os.path.abspath(os.path.realpath(value))
        if tmp.startswith(self._top_dir):
            dict.__setitem__(self, name, tmp)
        else:
            raise ValueError("parameter {0} is not under top_dir".format(name))
    def __getitem__(self, name):
        return dict.__getitem__(self, name)
