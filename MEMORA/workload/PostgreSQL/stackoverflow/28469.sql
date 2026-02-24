WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(P.ViewCount) AS AvgViewCount,
        AVG(P.Score) AS AvgScore
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
),
UserInteractions AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Comments C ON C.UserId = U.Id
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    TS.TagName,
    TS.PostCount,
    TS.QuestionCount,
    TS.AnswerCount,
    TS.AvgViewCount,
    TS.AvgScore,
    UI.UserId,
    UI.DisplayName,
    UI.CommentCount,
    UI.VoteCount,
    UI.GoldBadgeCount,
    UI.SilverBadgeCount,
    UI.BronzeBadgeCount
FROM 
    TagStats TS
JOIN 
    UserInteractions UI ON TS.PostCount > 5
ORDER BY 
    TS.AvgScore DESC,
    UI.CommentCount DESC
LIMIT 10;
