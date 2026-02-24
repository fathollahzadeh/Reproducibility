
WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesTotal,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesTotal,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views
),
ActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        R.UserRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    JOIN 
        RankedUsers R ON U.Id = R.UserId
    WHERE 
        P.LastActivityDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
PostInteraction AS (
    SELECT 
        AP.PostId,
        AP.Title,
        AP.OwnerDisplayName,
        AP.CreationDate,
        AP.Score,
        AP.ViewCount,
        AP.AnswerCount,
        AP.CommentCount,
        COUNT(C.Id) AS TotalCommentCount
    FROM 
        ActivePosts AP
    LEFT JOIN 
        Comments C ON AP.PostId = C.PostId
    GROUP BY 
        AP.PostId, AP.Title, AP.OwnerDisplayName, AP.CreationDate, AP.Score, AP.ViewCount, AP.AnswerCount, AP.CommentCount
)
SELECT 
    R.UserId, 
    R.DisplayName, 
    R.Reputation, 
    R.BadgeCount, 
    R.UpVotesTotal, 
    R.DownVotesTotal,
    P.PostId,
    P.Title,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount
FROM 
    RankedUsers R
JOIN 
    PostInteraction P ON R.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = P.PostId)
ORDER BY 
    R.Reputation DESC, P.ViewCount DESC
LIMIT 10;
