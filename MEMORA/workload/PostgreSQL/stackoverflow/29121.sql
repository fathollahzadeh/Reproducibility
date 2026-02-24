WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        AVG(U.Reputation) AS AverageUserReputation
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        T.TagName
), 
PostTypeStatistics AS (
    SELECT 
        PT.Name AS PostTypeName,
        COUNT(P.Id) AS TotalPosts,
        AVG(EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - P.CreationDate)) / 3600) AS AvgPostAgeInHours
    FROM 
        PostTypes PT
    LEFT JOIN 
        Posts P ON P.PostTypeId = PT.Id
    GROUP BY 
        PT.Name
), 
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostsCreated,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBountyEarned
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON V.UserId = U.Id AND V.VoteTypeId IN (1, 2) 
    GROUP BY 
        U.Id, U.DisplayName
), 
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        T.TagName,
        U.DisplayName AS OwnerName
    FROM 
        Posts P
    JOIN 
        Tags T ON P.Tags LIKE '%' || T.TagName || '%'
    JOIN 
        Users U ON P.OwnerUserId = U.Id
)
SELECT 
    TS.TagName,
    TS.PostCount,
    TS.CommentCount,
    TS.AverageUserReputation,
    PTS.PostTypeName,
    PTS.TotalPosts,
    PTS.AvgPostAgeInHours,
    UA.DisplayName AS TopContributor,
    UA.PostsCreated,
    UA.TotalBountyEarned,
    PD.Title,
    PD.Score,
    PD.ViewCount,
    PD.OwnerName
FROM 
    TagStatistics TS
JOIN 
    PostTypeStatistics PTS ON TS.PostCount > 10 
JOIN 
    UserActivity UA ON UA.PostsCreated = (SELECT MAX(PostsCreated) FROM UserActivity)
JOIN 
    PostDetails PD ON PD.OwnerName = UA.DisplayName
ORDER BY 
    TS.PostCount DESC, 
    PTS.TotalPosts DESC, 
    UA.TotalBountyEarned DESC
LIMIT 10;