
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        AVG(EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - U.CreationDate)) / 86400) AS AccountAgeDays
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
    ORDER BY 
        P.Score DESC
    LIMIT 10
),
PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount, 
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount 
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.Id
)
SELECT 
    UR.DisplayName,
    UR.Reputation,
    UR.BadgeCount,
    UR.AccountAgeDays,
    TP.Title,
    TP.Score AS PostScore,
    TP.ViewCount AS PostViewCount,
    PE.CommentCount,
    PE.UpvoteCount,
    PE.DownvoteCount
FROM 
    UserReputation UR
JOIN 
    TopPosts TP ON UR.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = TP.PostId)
JOIN 
    PostEngagement PE ON TP.PostId = PE.PostId
ORDER BY 
    UR.Reputation DESC, TP.Score DESC;
