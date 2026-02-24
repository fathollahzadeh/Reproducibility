
WITH RecursiveUserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        CAST(0 AS INTEGER) AS PostScore,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS DownvotedPosts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate
),
UserActivity AS (
    SELECT 
        UserId,
        DisplayName,
        MAX(CreationDate) AS LastActiveDate,
        SUM(PostScore) AS TotalPostScores,
        AVG(Reputation) AS AvgReputation
    FROM 
        RecursiveUserStats
    WHERE 
        LastAccessDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 YEAR'
    GROUP BY 
        UserId, DisplayName
),
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(C) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 MONTH'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount
),
CombinedStats AS (
    SELECT 
        UA.DisplayName,
        UA.LastActiveDate,
        UA.TotalPostScores,
        UA.AvgReputation,
        PA.Title AS ActivePostTitle,
        PA.TotalBounty,
        PA.CommentCount
    FROM 
        UserActivity UA
    RIGHT JOIN 
        PostAnalytics PA ON UA.UserId = PA.PostId
)
SELECT 
    CS.DisplayName,
    COALESCE(CS.ActivePostTitle, 'No Active Posts') AS ActivePostTitle,
    COALESCE(CS.TotalPostScores, 0) AS TotalPostScores,
    COALESCE(CS.AvgReputation, 0) AS AvgReputation,
    COALESCE(CS.TotalBounty, 0) AS TotalBounty,
    COALESCE(CS.CommentCount, 0) AS CommentCount
FROM 
    CombinedStats CS
ORDER BY 
    CS.LastActiveDate DESC
LIMIT 100;
