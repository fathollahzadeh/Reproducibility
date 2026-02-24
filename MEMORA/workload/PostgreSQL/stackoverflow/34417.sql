
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.ViewCount,
        P.Score,
        P.CreationDate,
        P.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rank,
        P.OwnerUserId
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 
),
AggregateUserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(P.Score) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(P.ViewCount, 0)) AS AvgViews,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT V.Id) AS VoteCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
UserEngagement AS (
    SELECT 
        A.UserId,
        A.DisplayName,
        A.QuestionCount,
        A.TotalScore,
        A.TotalViews,
        A.AvgViews,
        A.BadgeCount,
        A.VoteCount,
        R.PostId AS TopPostId,
        R.Title AS TopPostTitle,
        R.Score AS TopPostScore
    FROM 
        AggregateUserStats A
    LEFT JOIN 
        RankedPosts R ON A.UserId = R.OwnerUserId AND R.Rank = 1
)
SELECT 
    UE.DisplayName,
    UE.QuestionCount,
    UE.TotalScore,
    UE.TotalViews,
    UE.AvgViews,
    UE.BadgeCount,
    UE.VoteCount,
    COALESCE(UE.TopPostTitle, 'No Questions Yet') AS TopPostTitle,
    COALESCE(UE.TopPostScore, 0) AS TopPostScore
FROM 
    UserEngagement UE
ORDER BY 
    UE.TotalScore DESC, 
    UE.QuestionCount DESC
LIMIT 10;
