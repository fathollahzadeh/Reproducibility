
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.Score) AS TotalScore,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        P.LastActivityDate,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.CreationDate, P.LastActivityDate
)
SELECT 
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.Questions,
    U.Answers,
    U.TotalScore,
    U.CommentCount AS UserCommentCount,
    U.BadgeCount,
    P.PostId,
    P.Title AS PostTitle,
    P.ViewCount,
    P.CreationDate AS PostCreationDate,
    P.LastActivityDate,
    P.CommentCount AS PostCommentCount,
    P.Upvotes,
    P.Downvotes
FROM 
    UserStats U
JOIN 
    PostStats P ON U.UserId = P.PostId
ORDER BY 
    U.Reputation DESC, P.ViewCount DESC;
