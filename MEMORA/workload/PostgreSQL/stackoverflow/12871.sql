
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.Score,
        P.ViewCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN A.Id IS NOT NULL THEN 1 END) AS AnswerCount,
        P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    GROUP BY 
        P.Id, P.Title, P.PostTypeId, P.Score, P.ViewCount, P.OwnerUserId
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT PostStats.PostId) AS PostsCount,
        SUM(PostStats.Score) AS TotalScore,
        SUM(PostStats.ViewCount) AS TotalViewCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        PostStats ON U.Id = PostStats.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    U.PostsCount,
    U.TotalScore,
    U.TotalViewCount
FROM 
    UserStats U
ORDER BY 
    U.Reputation DESC, 
    U.PostsCount DESC;
