WITH TagWordCount AS (
    SELECT 
        TagName,
        SUM(LENGTH(Tags) - LENGTH(REPLACE(Tags, '<', '')) / LENGTH('<')) AS TagCount,
        COUNT(*) as PostCount
    FROM 
        Tags
    INNER JOIN 
        Posts ON Tags.Id = Posts.Id
    WHERE 
        Posts.PostTypeId = 1 
    GROUP BY 
        TagName
),
UsersWithBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
HighReputationUsers AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
),
QuestionStatistics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS QuestionCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    U.DisplayName AS User,
    U.Reputation,
    UA.BadgeCount,
    UA.GoldBadges,
    UA.SilverBadges,
    UA.BronzeBadges,
    QS.QuestionCount,
    QS.TotalScore,
    QS.AvgViewCount,
    TW.TagName,
    TW.TagCount,
    TW.PostCount
FROM 
    HighReputationUsers U
LEFT JOIN 
    UsersWithBadges UA ON U.UserId = UA.UserId
LEFT JOIN 
    QuestionStatistics QS ON U.UserId = QS.OwnerUserId
LEFT JOIN 
    (SELECT TagName, 
        COUNT(*) AS TagCount, 
        SUM(PostCount) AS PostCount
    FROM 
        TagWordCount
    GROUP BY 
        TagName
    HAVING
        COUNT(*) > 5) TW ON 1=1 
ORDER BY 
    U.Reputation DESC, 
    QS.TotalScore DESC;