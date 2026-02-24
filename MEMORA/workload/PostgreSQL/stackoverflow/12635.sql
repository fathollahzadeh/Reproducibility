
WITH PostCounts AS (
    SELECT 
        PostTypeId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Posts
    GROUP BY 
        PostTypeId
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation
),
MostActiveUsers AS (
    SELECT 
        UserId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        UserId
    ORDER BY 
        CommentCount DESC
    LIMIT 10
)
SELECT 
    PC.PostTypeId,
    PC.TotalPosts,
    PC.AcceptedAnswers,
    MAX(UR.Reputation) AS HighestReputation,
    SUM(UR.BadgeCount) AS TotalBadges,
    MA.CommentCount AS MostComments
FROM 
    PostCounts PC
JOIN 
    Users U ON (U.Id IN (SELECT UserId FROM MostActiveUsers))
JOIN 
    UserReputation UR ON (U.Id = UR.UserId)
JOIN 
    (SELECT UserId, SUM(CommentCount) AS CommentCount 
     FROM MostActiveUsers 
     GROUP BY UserId) MA ON (MA.UserId = U.Id)
GROUP BY 
    PC.PostTypeId, PC.TotalPosts, PC.AcceptedAnswers, MA.CommentCount
ORDER BY 
    PC.TotalPosts DESC;
