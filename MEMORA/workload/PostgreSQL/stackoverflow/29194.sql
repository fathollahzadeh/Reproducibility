
WITH TagCounts AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
),
UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsPosted,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersPosted,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostHistoryAnalysis AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        PH.PostId, PH.PostHistoryTypeId
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
    WHERE 
        PostCount > 0
    ORDER BY 
        PostCount DESC
    LIMIT 10
)

SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    COALESCE(UA.TotalPosts, 0) AS TotalPosts,
    COALESCE(UA.QuestionsPosted, 0) AS QuestionsPosted,
    COALESCE(UA.AnswersPosted, 0) AS AnswersPosted,
    COALESCE(UA.GoldBadges, 0) AS GoldBadges,
    COALESCE(UA.SilverBadges, 0) AS SilverBadges,
    COALESCE(UA.BronzeBadges, 0) AS BronzeBadges,
    T.TagName,
    T.PostCount
FROM 
    Users U
LEFT JOIN 
    UserStatistics UA ON U.Id = UA.UserId
INNER JOIN 
    TopTags T ON TRUE 
ORDER BY 
    U.Reputation DESC, T.PostCount DESC;
