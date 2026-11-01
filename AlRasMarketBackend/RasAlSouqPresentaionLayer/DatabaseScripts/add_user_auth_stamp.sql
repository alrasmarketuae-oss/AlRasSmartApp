-- Ends a session on logout / password change. Existing rows stay at 0 so current tokens keep working until the user logs out.
IF COL_LENGTH('dbo.Users', 'AuthStamp') IS NULL
BEGIN
    ALTER TABLE dbo.Users
        ADD AuthStamp int NOT NULL CONSTRAINT DF_Users_AuthStamp DEFAULT (0);
END
