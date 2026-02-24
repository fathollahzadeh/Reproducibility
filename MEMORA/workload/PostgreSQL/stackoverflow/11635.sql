
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END, 0)) AS QuestionCount,
        SUM(COALESCE(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END, 0)) AS AnswerCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS UpVotesCount,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS DownVotesCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
BadgeStatistics AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    US.DisplayName,
    US.PostCount,
    US.TotalScore,
    US.QuestionCount,
    US.AnswerCount,
    US.TotalViews,
    US.UpVotesCount,
    US.DownVotesCount,
    COALESCE(BS.BadgeCount, 0) AS BadgeCount,
    COALESCE(BS.GoldBadges, 0) AS GoldBadges,
    COALESCE(BS.SilverBadges, 0) AS SilverBadges,
    COALESCE(BS.BronzeBadges, 0) AS BronzeBadges
FROM 
    UserStatistics US
LEFT JOIN 
    BadgeStatistics BS ON US.UserId = BS.UserId
ORDER BY 
    US.TotalScore DESC
FETCH FIRST 100 ROWS ONLY;
