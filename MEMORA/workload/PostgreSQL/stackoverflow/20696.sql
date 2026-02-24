
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId 
    WHERE 
        U.Reputation > 100
    GROUP BY 
        U.Id, U.DisplayName
),
RecentActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalViews,
        TotalScore,
        LastPostDate,
        RANK() OVER (ORDER BY LastPostDate DESC) AS ActivityRank
    FROM 
        UserActivity
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id 
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
        AND P.Score IS NOT NULL
),
RecentComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN C.UserId IS NOT NULL THEN 1 ELSE 0 END) AS UserComments
    FROM 
        Comments C
    GROUP BY 
        C.PostId
),
PostLinkStats AS (
    SELECT
        PL.PostId, 
        COUNT(PL.RelatedPostId) AS RelatedLinks
    FROM 
        PostLinks PL
    GROUP BY 
        PL.PostId
)
SELECT 
    U.UserId, 
    U.DisplayName, 
    U.TotalPosts, 
    U.TotalScore, 
    U.TotalViews, 
    U.LastPostDate,
    COALESCE(PP.Title, 'No Posts') AS PopularPostTitle,
    PP.ViewCount AS PopularPostViews,
    COALESCE(PC.CommentCount, 0) AS CommentCount,
    COALESCE(PL.RelatedLinks, 0) AS RelatedLinks
FROM 
    RecentActiveUsers U
LEFT JOIN 
    TopPosts PP ON U.UserId = PP.OwnerUserId AND PP.PostRank = 1
LEFT JOIN 
    RecentComments PC ON PP.PostId = PC.PostId
LEFT JOIN 
    PostLinkStats PL ON PP.PostId = PL.PostId
WHERE 
    U.ActivityRank <= 10
ORDER BY 
    U.LastPostDate DESC;
