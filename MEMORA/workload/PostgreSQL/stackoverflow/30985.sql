
WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.LastAccessDate,
        1 AS Level
    FROM 
        Users U
    WHERE 
        U.Reputation > 0

    UNION ALL

    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.LastAccessDate,
        UR.Level + 1
    FROM 
        Users U
    INNER JOIN 
        Votes V ON U.Id = V.UserId
    INNER JOIN 
        UserReputationCTE UR ON V.PostId IN (
            SELECT P.Id 
            FROM Posts P 
            WHERE P.OwnerUserId = UR.Id
        )
    WHERE 
        UR.Level < 3
)

, PostWithComments AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        P.CreationDate,
        P.LastActivityDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId 
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, P.LastActivityDate
)

, RankedPosts AS (
    SELECT 
        P.Title,
        P.CommentCount,
        P.CreationDate,
        RANK() OVER (ORDER BY P.CommentCount DESC) AS RankByComments
    FROM 
        PostWithComments P
)

SELECT 
    UR.DisplayName,
    UR.Reputation,
    P.Title,
    P.CommentCount,
    P.RankByComments,
    P.CreationDate
FROM 
    UserReputationCTE UR
JOIN 
    RankedPosts P ON P.RankByComments <= 10
WHERE 
    UR.LastAccessDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
    AND UR.Reputation > 100
ORDER BY 
    UR.Reputation DESC, P.RankByComments;
