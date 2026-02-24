WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Location,
        U.LastAccessDate,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    WHERE 
        U.Reputation IS NOT NULL AND U.Reputation > 1000 
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Location, U.LastAccessDate
),
PostMetrics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        MAX(P.Score) AS HighestScore,
        AVG(P.ViewCount) AS AvgViews,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM 
        Posts P
    LEFT JOIN 
        Tags T ON P.Tags LIKE '%' || T.TagName || '%' 
    GROUP BY 
        P.OwnerUserId
),
RankedPosts AS (
    SELECT 
        PM.OwnerUserId,
        PM.TotalPosts,
        PM.Questions,
        PM.Answers,
        PM.HighestScore,
        PM.AvgViews,
        RANK() OVER (ORDER BY PM.TotalPosts DESC, PM.HighestScore DESC) AS PostRank
    FROM 
        PostMetrics PM
),
CombinedMetrics AS (
    SELECT 
        UR.UserId, 
        UR.DisplayName, 
        UR.Reputation,
        UR.Location,
        PM.TotalPosts,
        PM.Questions,
        PM.Answers,
        PM.HighestScore,
        PM.AvgViews,
        PM.Tags,
        RM.PostRank
    FROM 
        UserReputation UR
    LEFT JOIN 
        RankedPosts RM ON UR.UserId = RM.OwnerUserId
    LEFT JOIN 
        PostMetrics PM ON UR.UserId = PM.OwnerUserId
)
SELECT 
    CM.DisplayName,
    COALESCE(CM.Reputation, 0) AS Reputation,
    COALESCE(CM.TotalPosts, 0) AS TotalPosts,
    COALESCE(CM.Questions, 0) AS Questions,
    COALESCE(CM.Answers, 0) AS Answers,
    COALESCE(CM.HighestScore, 0) AS HighestScore,
    COALESCE(CM.AvgViews, 0) AS AvgViews,
    COALESCE(CM.Tags, 'No Tags') AS Tags,
    CASE 
        WHEN CM.PostRank IS NULL THEN 'No Activity'
        ELSE 'Active User'
    END AS UserActivityStatus
FROM 
    CombinedMetrics CM
WHERE 
    (CM.Reputation > 500 OR CM.TotalPosts > 10) 
ORDER BY 
    COALESCE(CM.Reputation, 0) DESC, COALESCE(CM.TotalPosts, 0) DESC;