
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
),
ActivePosts AS (
    SELECT 
        P.Id AS PostId, 
        P.OwnerUserId, 
        P.Title, 
        P.ViewCount, 
        P.CreationDate,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswerFlag,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.OwnerUserId, P.Title, P.ViewCount, P.CreationDate
),
TopVotedPosts AS (
    SELECT 
        AP.PostId, 
        AP.Title, 
        AP.ViewCount, 
        U.DisplayName AS OwnerName,
        V.VoteCount
    FROM 
        ActivePosts AP
    JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount
        FROM 
            Votes
        WHERE 
            VoteTypeId = 2 
        GROUP BY 
            PostId
    ) V ON AP.PostId = V.PostId
    JOIN Users U ON AP.OwnerUserId = U.Id
    WHERE 
        V.VoteCount > 5
),
RecentUpdates AS (
    SELECT 
        PH.PostId, 
        COUNT(*) AS UpdateCount,
        MAX(PH.CreationDate) AS LastUpdateDate
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        PH.PostId
)
SELECT 
    ROUND(AVG(Reputation.Reputation), 2) AS AverageUserReputation,
    SUM(CASE WHEN T.VoteCount > 10 THEN 1 ELSE 0 END) AS HighlyVotedPosts,
    COUNT(DISTINCT RU.PostId) AS PostsWithRecentUpdates
FROM 
    TopVotedPosts T
LEFT JOIN 
    UserReputation Reputation ON T.OwnerName = Reputation.DisplayName
LEFT JOIN 
    RecentUpdates RU ON T.PostId = RU.PostId
GROUP BY 
    Reputation.Reputation
HAVING 
    AVG(Reputation.Reputation) > 1000
ORDER BY 
    AverageUserReputation DESC;
