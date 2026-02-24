
WITH RECURSIVE UserHierarchy AS (
    SELECT Id, DisplayName, Reputation, CreationDate, LastAccessDate, 0 AS Level
    FROM Users
    WHERE Reputation > 1000  

    UNION ALL

    SELECT u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.LastAccessDate, uh.Level + 1
    FROM Users u
    JOIN UserHierarchy uh ON u.Id = (SELECT MAX(Id) FROM Users WHERE Reputation < uh.Reputation)  
),
PostSummary AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM Posts p
    GROUP BY p.OwnerUserId
),
VoteSummary AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes, 
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes 
    FROM Votes v
    GROUP BY v.PostId
),
UserPostDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        uh.Reputation,
        ps.PostCount,
        ps.TotalScore,
        ps.LastPostDate,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        CASE 
            WHEN uh.Reputation IS NULL THEN 'No Reputation' 
            WHEN uh.Level = 0 THEN 'New Member' 
            ELSE CAST(uh.Level AS TEXT) || ' Level User' 
        END AS UserLevel
    FROM Users u
    LEFT JOIN UserHierarchy uh ON u.Id = uh.Id
    LEFT JOIN PostSummary ps ON u.Id = ps.OwnerUserId
    LEFT JOIN VoteSummary vs ON ps.OwnerUserId = vs.PostId
)
SELECT 
    u.UserId, 
    u.DisplayName,
    u.Reputation,
    u.PostCount,
    u.TotalScore,
    u.LastPostDate,
    u.UpVotes,
    u.DownVotes,
    u.UserLevel
FROM UserPostDetails u
WHERE u.PostCount > 5  
ORDER BY u.TotalScore DESC, u.LastPostDate DESC
LIMIT 10  
