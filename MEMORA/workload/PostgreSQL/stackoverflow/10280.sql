WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(V.Id, 0)) AS VoteCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.Reputation
), BadgeStats AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COALESCE(US.PostCount, 0) AS TotalPosts,
    COALESCE(US.QuestionCount, 0) AS TotalQuestions,
    COALESCE(US.AnswerCount, 0) AS TotalAnswers,
    COALESCE(US.VoteCount, 0) AS TotalVotes,
    COALESCE(BS.BadgeCount, 0) AS TotalBadges,
    COALESCE(BS.GoldBadgeCount, 0) AS TotalGoldBadges,
    COALESCE(BS.SilverBadgeCount, 0) AS TotalSilverBadges,
    COALESCE(BS.BronzeBadgeCount, 0) AS TotalBronzeBadges
FROM 
    Users U
LEFT JOIN 
    UserStats US ON U.Id = US.UserId
LEFT JOIN 
    BadgeStats BS ON U.Id = BS.UserId
ORDER BY 
    U.Reputation DESC;