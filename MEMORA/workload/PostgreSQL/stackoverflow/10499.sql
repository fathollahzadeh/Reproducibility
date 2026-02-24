
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.CreationDate IS NOT NULL THEN 1 ELSE 0 END) AS VoteCount,
        SUM(CASE WHEN C.CreationDate IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount,
        MIN(P.CreationDate) AS FirstPostDate,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
UserRanks AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        VoteCount,
        CommentCount,
        BadgeCount,
        TotalScore,
        AvgViewCount,
        FirstPostDate,
        LastPostDate,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserStats
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    VoteCount,
    CommentCount,
    BadgeCount,
    TotalScore,
    AvgViewCount,
    FirstPostDate,
    LastPostDate,
    ScoreRank
FROM 
    UserRanks
WHERE 
    PostCount > 0
ORDER BY 
    ScoreRank;
