WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        RANK() OVER (ORDER BY P.ViewCount DESC) AS ViewRank
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1 AND 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        P.Id
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Upvotes,
        Downvotes,
        CommentCount,
        ViewRank
    FROM 
        RankedPosts
    WHERE 
        ViewRank <= 10
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    T.Title,
    T.CreationDate,
    T.ViewCount,
    T.Upvotes,
    T.Downvotes,
    T.CommentCount,
    U.DisplayName,
    B.BadgeCount
FROM 
    TopPosts T
JOIN 
    Posts P ON T.PostId = P.Id
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    UserBadges B ON U.Id = B.UserId
ORDER BY 
    T.ViewCount DESC, T.Upvotes DESC;