WITH TagStats AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END, 0)) AS QuestionCount,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END, 0)) AS AnswerCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%' 
    GROUP BY 
        T.Id, T.TagName
),
BadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PopularTags AS (
    SELECT 
        TagId,
        TagName,
        PostCount,
        TotalViews,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        TagStats
),
HighlyActiveUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COALESCE(BC.BadgeCount, 0) AS BadgeCount,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsSubmitted,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersSubmitted
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        BadgeCounts BC ON U.Id = BC.UserId
    GROUP BY 
        U.Id, U.DisplayName, BC.BadgeCount
)
SELECT 
    PT.TagName,
    PT.PostCount,
    PT.TotalViews,
    PT.QuestionCount,
    PT.AnswerCount,
    AU.DisplayName AS ActiveUser,
    AU.TotalPosts,
    AU.BadgeCount
FROM 
    PopularTags PT
JOIN 
    HighlyActiveUsers AU ON AU.QuestionsSubmitted > 0
WHERE 
    PT.ViewRank <= 10
ORDER BY 
    PT.TotalViews DESC, AU.BadgeCount DESC;
