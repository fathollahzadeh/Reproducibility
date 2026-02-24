
WITH PostTagCounts AS (
    SELECT 
        P.Id AS PostId,
        COUNT(DISTINCT T.TagName) AS UniqueTagCount
    FROM 
        Posts P
    LEFT JOIN 
        Tags T ON POSITION(CONCAT('<', T.TagName, '>') IN P.Tags) > 0
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(COALESCE(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END, 0)) AS GoldBadgeCount,
        SUM(COALESCE(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END, 0)) AS SilverBadgeCount,
        SUM(COALESCE(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END, 0)) AS BronzeBadgeCount,
        COALESCE(SUM(P.Score), 0) AS TotalScore,
        AVG(TC.UniqueTagCount) AS AvgTagsPerQuestion
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    LEFT JOIN 
        PostTagCounts TC ON TC.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
),
MostActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        GoldBadgeCount,
        SilverBadgeCount,
        BronzeBadgeCount,
        TotalScore,
        AvgTagsPerQuestion,
        ROW_NUMBER() OVER (ORDER BY QuestionCount DESC) AS Rank
    FROM 
        UserPostStats
    WHERE 
        QuestionCount > 0
)
SELECT 
    Rank,
    DisplayName,
    QuestionCount,
    GoldBadgeCount,
    SilverBadgeCount,
    BronzeBadgeCount,
    TotalScore,
    AvgTagsPerQuestion
FROM 
    MostActiveUsers
WHERE 
    Rank <= 10
ORDER BY 
    TotalScore DESC;
