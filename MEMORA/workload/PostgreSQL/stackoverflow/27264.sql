
WITH TagStats AS (
    SELECT 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) AS TagName,
        COUNT(Id) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
), 

UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(COALESCE(P.CommentCount, 0)) AS AvgCommentsPerPost
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),

PostHistoryStats AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(*) AS EditCount, 
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId, PH.PostHistoryTypeId
),

RankedUsers AS (
    SELECT 
        U.UserId, 
        U.DisplayName, 
        RANK() OVER (ORDER BY U.TotalScore DESC) AS ScoreRank
    FROM 
        UserStats U
)

SELECT 
    TS.TagName,
    TS.PostCount,
    TS.QuestionCount,
    TS.AnswerCount,
    US.DisplayName AS TopUser,
    US.BadgeCount,
    US.TotalViews,
    US.TotalScore,
    US.AvgCommentsPerPost,
    PHS.EditCount,
    PHS.LastEditDate
FROM 
    TagStats TS
JOIN 
    RankedUsers RU ON RU.UserId = (SELECT U.Id FROM Users U WHERE U.Reputation = (SELECT MAX(Reputation) FROM Users))
JOIN 
    UserStats US ON US.UserId = (SELECT UserId FROM UserStats ORDER BY TotalScore DESC LIMIT 1)
JOIN 
    PostHistoryStats PHS ON PHS.PostId = (SELECT Id FROM Posts ORDER BY Score DESC LIMIT 1)
ORDER BY 
    TS.PostCount DESC, US.TotalScore DESC;
