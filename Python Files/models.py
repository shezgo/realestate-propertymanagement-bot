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
        Database.insert(Query.INSERT_REGISTERED_USER, values = data)
        return ModelFactory.getBy(table_identifier, data[0])

    @staticmethod
    def getBy(table_identifier, entity_identifier):
        if table_identifier == Tables.REGISTERED_USERS: 
            return RegisteredUserModel(entity_identifier)


class RegisteredUserModel(ModelInterface):

    def __init__(self, identifier):
        self.tracking_id = identifier
        self.email = None
        self.first_name = None
        self.last_name = None
        self.role_id = None
        self._load()

    def _load(self):
        data = Database.select(Query.REGISTERED_USER, (self.tracking_id,))
        if not data:
            return

        row = data[0]
        self.email = row["email"]
        self.first_name = row["first_name"]
        self.last_name = row["last_name"]
        self.role_id = row["role_id"]
