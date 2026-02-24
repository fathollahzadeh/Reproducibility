WITH RECURSIVE UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName AS UserDisplayName,
        U.Reputation,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswers,
        P.CreationDate AS PostCreationDate,
        P.Score AS PostScore,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY P.CreationDate DESC) AS ActivityRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
), 

UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS Badges
    FROM 
        Badges B
    WHERE 
        B.Date >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        B.UserId
),

PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS VoteCount,
        AVG(P.Score) OVER (PARTITION BY P.OwnerUserId) AS AvgPostScore,
        COUNT(*) AS TotalPosts
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.OwnerUserId
)

SELECT
    UA.UserId,
    UA.UserDisplayName,
    UA.Reputation,
    UA.AcceptedAnswers,
    UA.PostCreationDate,
    UA.PostScore,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    COALESCE(UB.Badges, 'No badges') AS Badges,
    PS.CommentCount,
    PS.VoteCount,
    PS.AvgPostScore,
    PS.TotalPosts
FROM 
    UserActivity UA
LEFT JOIN 
    UserBadges UB ON UA.UserId = UB.UserId
LEFT JOIN 
    PostStatistics PS ON UA.UserId = PS.OwnerUserId
WHERE 
    UA.ActivityRank <= 10
ORDER BY 
    UA.Reputation DESC,
    UA.PostCreationDate DESC;