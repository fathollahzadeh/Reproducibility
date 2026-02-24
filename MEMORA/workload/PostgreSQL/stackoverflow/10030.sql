
WITH Benchmark AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS VoteCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        P.CreationDate >= '2023-01-01'
    GROUP BY 
        P.Id, P.Title, U.DisplayName, P.Score, P.ViewCount, P.CreationDate
)
SELECT 
    PostId,
    Title,
    OwnerDisplayName,
    Score,
    ViewCount,
    CreationDate,
    CommentCount,
    VoteCount,
    BadgeCount,
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Comments) AS TotalComments,
    (SELECT COUNT(*) FROM Votes) AS TotalVotes,
    (SELECT COUNT(*) FROM Badges) AS TotalBadges
FROM 
    Benchmark
ORDER BY 
    Score DESC, ViewCount DESC;
