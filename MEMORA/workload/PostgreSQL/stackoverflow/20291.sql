WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        U.DisplayName,
        (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id) AS BadgeCount,
        (SELECT COUNT(DISTINCT P.Id) FROM Posts P WHERE P.OwnerUserId = U.Id AND P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year') AS PostsLastYear,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL
),

PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.PostTypeId,
        P.Score,
        P.ViewCount,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpvoteCount,  
        CASE WHEN P.Body IS NULL OR P.Body = '' THEN 'No content' ELSE 'Has content' END AS ContentStatus
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),

TopUserPosts AS (
    SELECT 
        U.UserId,
        P.PostId,
        P.Title,
        P.Score,
        U.Reputation AS UserReputation,
        RANK() OVER (PARTITION BY U.UserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        UserStats U
    JOIN 
        PostDetails P ON U.UserId = P.OwnerUserId
    WHERE 
        U.Reputation >= 1000
)

SELECT 
    U.DisplayName,
    UP.PostId,
    UP.Title,
    UP.Score,
    UP.UserReputation,
    CASE 
        WHEN UP.PostRank = 1 THEN 'Top Post'
        WHEN UP.PostRank <= 5 THEN 'High Rank Post'
        ELSE 'Other Post'
    END AS PostType,
    (SELECT STRING_AGG(DISTINCT T.TagName, ', ') 
     FROM Posts P 
     JOIN Tags T ON T.WikiPostId = P.Id 
     WHERE P.Id = UP.PostId) AS AssociatedTags,
    PH.CreationDate AS LastEditDate,
    PH.Comment AS LastEditComment
FROM 
    TopUserPosts UP
LEFT JOIN 
    PostHistory PH ON PH.PostId = UP.PostId AND PH.PostHistoryTypeId IN (4, 5, 6)  
JOIN 
    Users U ON UP.UserId = U.Id
WHERE 
    (U.Location IS NOT NULL AND U.Location <> '')
    OR (U.Location IS NULL AND U.Reputation > 500)
ORDER BY 
    U.Reputation DESC, UP.UserId, UP.PostRank
LIMIT 100;