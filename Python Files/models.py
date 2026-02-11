"""
IMPORTANT: To receive credit for this project, ensure that no direct database logic or queries are included in this file.
This file is strictly for implementing Object Relational Modeling (ORM) functionality for your database.

The models implemented in this file are responsible for defining the structure and behavior of the data entities
without directly handling raw database transactions, ensuring a clear
separation of concerns between the ORM layer and direct database interaction.
"""

from database import *

class ModelInterface:

    def synchronize(self):
        pass

    def update(self, data):
        pass

    def delete(self, condition = None):
        pass

    def unwrap(self):
        pass

    class ModelFactory:
        # Makes and gets all the models

        @staticmethod
        def make(table_identifier, data):
            Database.insert(data, into: Table)
            return Model.getBy(data.id)


