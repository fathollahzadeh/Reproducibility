WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COALESCE(P.PostCount, 0) AS PostCount,
        COALESCE(C.CommentCount, 0) AS CommentCount,
        COALESCE(V.VoteCount, 0) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.CreationDate DESC) AS rn
    FROM 
        Users U
    LEFT JOIN (
        SELECT 
            OwnerUserId, 
            COUNT(Id) AS PostCount 
        FROM 
            Posts 
        GROUP BY 
            OwnerUserId
    ) P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(Id) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            UserId
    ) C ON U.Id = C.UserId
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(Id) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            UserId
    ) V ON U.Id = V.UserId
    WHERE 
        U.Reputation > 100
), RecentUserActivity AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Reputation DESC, PostCount DESC) AS Rank
    FROM 
        UserActivity
    WHERE 
        rn = 1
), MostCommentedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        C.CommentCount,
        ROW_NUMBER() OVER (ORDER BY C.CommentCount DESC) AS rn
    FROM 
        Posts P
    JOIN (
        SELECT 
            PostId, 
            COUNT(Id) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.CommentCount,
    P.Title,
    P.CommentCount AS PostCommentCount
FROM 
    RecentUserActivity U
LEFT JOIN 
    MostCommentedPosts P ON U.Rank = 1
WHERE 
    U.Rank <= 10
ORDER BY 
    U.Reputation DESC, 
    P.CommentCount DESC;
