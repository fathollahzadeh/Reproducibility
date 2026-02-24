WITH RECURSIVE UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        DisplayName,
        (Reputation + COALESCE((SELECT SUM(BountyAmount) FROM Votes WHERE UserId = U.Id AND BountyAmount IS NOT NULL), 0)) AS TotalReputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Ranking
    FROM 
        Users U
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.TotalReputation,
        RANK() OVER (ORDER BY U.TotalReputation DESC) AS Rank
    FROM 
        UserReputation U
    WHERE 
        U.CreationDate > cast('2024-10-01' as date) - INTERVAL '1 year'
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.TotalReputation,
    COALESCE(BadgeCount.BadgeCount, 0) AS BadgeCount,
    COALESCE(PostStats.PostCount, 0) AS PostCount,
    COALESCE(VoteStats.UpVoteCount, 0) AS UpVoteCount,
    COALESCE(VoteStats.DownVoteCount, 0) AS DownVoteCount,
    CASE 
        WHEN U.TotalReputation >= 5000 THEN 'High Reputation User'
        WHEN U.TotalReputation >= 1000 THEN 'Moderate Reputation User'
        ELSE 'New User'
    END AS UserCategory
FROM 
    TopUsers U
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS BadgeCount FROM Badges GROUP BY UserId) BadgeCount 
    ON U.Id = BadgeCount.UserId
LEFT JOIN 
    (SELECT OwnerUserId, COUNT(*) AS PostCount FROM Posts WHERE PostTypeId = 1 GROUP BY OwnerUserId) PostStats 
    ON U.Id = PostStats.OwnerUserId
LEFT JOIN 
    (SELECT UserId, 
             SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount, 
             SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount 
     FROM Votes 
     GROUP BY UserId) VoteStats 
    ON U.Id = VoteStats.UserId
WHERE 
    U.Rank <= 10
ORDER BY 
    U.TotalReputation DESC;