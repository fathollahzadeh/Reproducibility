
WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN U.Reputation >= 1000 THEN 'High' ELSE 'Low' END ORDER BY U.Reputation DESC) AS Rank,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
PostsData AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        P.OwnerUserId,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS NetVotes  
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.CreationDate, P.OwnerUserId
),
UserPosts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        PD.PostId,
        PD.Title,
        PD.Score,
        PD.ViewCount,
        PD.CreationDate,
        PD.CommentCount,
        PD.NetVotes,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY PD.CreationDate DESC) AS PostRank
    FROM 
        Users U
    JOIN 
        PostsData PD ON U.Id = PD.OwnerUserId
),
FeaturedPosts AS (
    SELECT 
        UP.UserId,
        UP.DisplayName,
        UP.PostId,
        UP.Title,
        UP.Score,
        UP.ViewCount,
        UP.CommentCount,
        UP.NetVotes
    FROM 
        UserPosts UP
    WHERE 
        UP.PostRank <= 5 AND UP.NetVotes > 10
),
AggregatedData AS (
    SELECT 
        R.DisplayName AS TopUser,
        SUM(FP.ViewCount) AS TotalViews,
        AVG(FP.Score) AS AverageScore,
        COUNT(DISTINCT FP.PostId) AS TotalPosts
    FROM 
        RankedUsers R
    JOIN 
        FeaturedPosts FP ON R.UserId = FP.UserId
    GROUP BY 
        R.DisplayName
)
SELECT 
    AD.TopUser,
    AD.TotalViews,
    AD.AverageScore,
    AD.TotalPosts,
    R.BadgeCount,
    CASE 
        WHEN AD.TotalViews >= 1000 THEN 'Highly Engaged'
        ELSE 'Moderately Engaged'
    END AS EngagementLevel,
    CASE 
        WHEN R.CreationDate < (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year') THEN 'Legacy User'
        ELSE 'Active User'
    END AS UserStatus
FROM 
    AggregatedData AD
JOIN 
    RankedUsers R ON AD.TopUser = R.DisplayName
ORDER BY 
    AD.TotalViews DESC, 
    AD.AverageScore DESC;
