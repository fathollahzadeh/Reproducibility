
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS TotalUpvotes,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS TotalDownvotes,
        SUM(CASE WHEN B.Name IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        (SELECT COUNT(*) 
         FROM Posts 
         WHERE OwnerUserId = U.Id AND CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR') AS RecentPostsLastYear
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),

PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.LastActivityDate DESC) AS rn
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments 
         GROUP BY PostId) pc ON P.Id = pc.PostId
    LEFT JOIN 
        (SELECT ParentId, COUNT(*) AS AnswerCount 
         FROM Posts 
         WHERE PostTypeId = 2 
         GROUP BY ParentId) a ON P.Id = a.ParentId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 DAY'
)

SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.Score,
    PD.ViewCount,
    PD.CommentCount,
    PD.AnswerCount,
    CASE 
        WHEN UA.Reputation > 1000 THEN 'Expert' 
        WHEN UA.Reputation BETWEEN 500 AND 1000 THEN 'Intermediate' 
        ELSE 'Novice' 
    END AS ExpertiseLevel,
    ARRAY_AGG(DISTINCT B.Name) AS BadgeNames
FROM 
    UserActivity UA
LEFT JOIN 
    PostDetails PD ON UA.UserId = PD.PostId
LEFT JOIN 
    Badges B ON UA.UserId = B.UserId
WHERE 
    (UA.Reputation IS NOT NULL OR UA.Reputation > 0) 
    AND (COALESCE(PD.ViewCount, 0) - COALESCE(PD.CommentCount, 0) > 10 OR PD.PostId IS NULL)
    AND PD.rn <= 3 
GROUP BY 
    UA.UserId, UA.DisplayName, UA.Reputation, PD.PostId, PD.Title, PD.CreationDate, PD.Score, PD.ViewCount, PD.CommentCount, PD.AnswerCount
ORDER BY 
    UA.Reputation DESC, PD.Score DESC
LIMIT 50;
