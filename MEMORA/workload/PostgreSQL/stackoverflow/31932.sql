
WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        1 AS Level
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL
    
    UNION ALL
    
    SELECT 
        U.Id,
        U.Reputation + 50, 
        UR.Level + 1
    FROM 
        Users U
    JOIN 
        UserReputationCTE UR ON U.Id = UR.UserId
    WHERE 
        UR.Level < 5
),

PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.PostTypeId,
        COUNT(C.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.Id = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.Id = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        P.CreationDate,
        P.Title
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (2, 3)
    GROUP BY 
        P.Id, P.OwnerUserId, P.PostTypeId, P.CreationDate, P.Title
),

BadgeSummary AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS HighestClass
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)

SELECT 
    U.DisplayName,
    UR.Reputation,
    PS.PostId,
    PS.Title,
    PS.CommentCount,
    PS.Upvotes,
    PS.Downvotes,
    BS.BadgeCount,
    CASE 
        WHEN PS.CommentCount > 10 THEN 'High Engagement' 
        ELSE 'Low Engagement' 
    END AS EngagementLevel,
    CASE 
        WHEN PS.Upvotes > PS.Downvotes THEN 'Positive' 
        ELSE 
            CASE 
                WHEN PS.Upvotes < PS.Downvotes THEN 'Negative'
                ELSE 'Neutral'
            END 
    END AS VoteSentiment,
    COALESCE(pg.Name, 'N/A') AS PostType,
    (SELECT AVG(Score) FROM Posts WHERE PostTypeId = PS.PostTypeId) AS AvgPostScore
FROM 
    Users U
JOIN 
    UserReputationCTE UR ON U.Id = UR.UserId
JOIN 
    PostStatistics PS ON U.Id = PS.OwnerUserId
LEFT JOIN 
    PostTypes pg ON PS.PostTypeId = pg.Id
LEFT JOIN 
    BadgeSummary BS ON U.Id = BS.UserId
WHERE 
    U.Reputation > 1000
ORDER BY 
    UR.Reputation DESC, PS.PostId DESC
LIMIT 50;
