WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(COALESCE(P.Score, 0)) AS AverageScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS UpVotes,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS DownVotes
    FROM 
        Users U 
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId 
    LEFT JOIN 
        Votes V ON P.Id = V.PostId 
    GROUP BY 
        U.Id, U.DisplayName
), BadgeStats AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Badges 
    GROUP BY 
        UserId
)
SELECT 
    U.DisplayName,
    COALESCE(US.PostCount, 0) AS PostCount,
    COALESCE(US.QuestionCount, 0) AS QuestionCount,
    COALESCE(US.AnswerCount, 0) AS AnswerCount,
    COALESCE(US.AverageScore, 0) AS AverageScore,
    COALESCE(US.TotalViews, 0) AS TotalViews,
    COALESCE(US.UpVotes, 0) AS UpVotes,
    COALESCE(US.DownVotes, 0) AS DownVotes,
    COALESCE(BS.BadgeCount, 0) AS BadgeCount,
    COALESCE(BS.GoldBadgeCount, 0) AS GoldBadgeCount,
    COALESCE(BS.SilverBadgeCount, 0) AS SilverBadgeCount,
    COALESCE(BS.BronzeBadgeCount, 0) AS BronzeBadgeCount
FROM 
    Users U
LEFT JOIN 
    UserStats US ON U.Id = US.UserId
LEFT JOIN 
    BadgeStats BS ON U.Id = BS.UserId
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.Reputation DESC, US.PostCount DESC
LIMIT 10;
