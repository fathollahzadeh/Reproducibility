WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostsCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY SUM(COALESCE(P.Score, 0)) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
ActiveUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation,
        PostsCount, 
        TotalBounty, 
        TotalViews
    FROM 
        UserActivity
    WHERE 
        Rank <= 10
),
ClosedPosts AS (
    SELECT 
        PH.UserId,
        COUNT(P.Id) AS ClosedPostsCount,
        SUM(P.ViewCount) AS ClosedPostsViews,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseVotes
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
        AND PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        PH.UserId
),
FinalStats AS (
    SELECT 
        AU.UserId,
        AU.DisplayName,
        AU.Reputation,
        AU.PostsCount,
        AU.TotalBounty,
        AU.TotalViews,
        COALESCE(CP.ClosedPostsCount, 0) AS ClosedPostsCount,
        COALESCE(CP.ClosedPostsViews, 0) AS ClosedPostsViews,
        COALESCE(CP.CloseVotes, 0) AS CloseVotes
    FROM 
        ActiveUsers AU
    LEFT JOIN 
        ClosedPosts CP ON AU.UserId = CP.UserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    PostsCount,
    TotalBounty,
    TotalViews,
    ClosedPostsCount,
    ClosedPostsViews,
    CloseVotes,
    (TotalViews / NULLIF(PostsCount, 0)) AS AvgViewsPerPost,
    (TotalBounty / NULLIF(ClosedPostsCount, 0)) AS AvgBountyPerClosedPost
FROM 
    FinalStats
ORDER BY 
    Reputation DESC, TotalViews DESC;