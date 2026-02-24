
WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.AnswerCount) AS TotalAnswers,
        AVG(P.ViewCount) AS AverageViews,
        MAX(P.CreationDate) AS MostRecentPost
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PopularQuestions AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.AnswerCount,
        P.ViewCount,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        T.TagName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Tags T ON P.Tags LIKE '%' || T.TagName || '%'
    WHERE 
        P.PostTypeId = 1 
    ORDER BY 
        P.Score DESC
    LIMIT 10
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBountySpent,
        AVG(P.ViewCount) AS AverageViewCount
    FROM 
        Users U
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    TS.TagName,
    TS.PostCount,
    TS.TotalAnswers,
    TS.AverageViews,
    TS.MostRecentPost,
    UB.DisplayName AS BadgeHolder,
    UB.BadgeCount,
    UB.GoldBadgeCount,
    UB.SilverBadgeCount,
    UB.BronzeBadgeCount,
    PQ.Title AS PopularQuestion,
    PQ.Score AS QuestionScore,
    PQ.ViewCount AS QuestionViewCount,
    PQ.OwnerDisplayName AS QuestionOwner,
    UA.CommentCount AS UserCommentCount,
    UA.TotalBountySpent,
    UA.AverageViewCount AS UserAverageViewCount
FROM 
    TagStats TS
JOIN 
    UserBadges UB ON UB.UserId = TS.PostCount 
JOIN 
    PopularQuestions PQ ON PQ.TagName = TS.TagName
JOIN 
    UserActivity UA ON UA.UserId = UB.UserId
ORDER BY 
    TS.PostCount DESC, UB.BadgeCount DESC;
