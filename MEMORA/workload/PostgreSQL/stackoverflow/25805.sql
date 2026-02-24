WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS Answers,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
BadgeSummary AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
TopAnswers AS (
    SELECT 
        P.OwnerUserId,
        COUNT(A.Id) AS TotalAcceptedAnswers,
        SUM(A.Score) AS AcceptedScore
    FROM 
        Posts P
    JOIN 
        Posts A ON P.AcceptedAnswerId = A.Id
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    UR.DisplayName AS UserName,
    UR.Reputation,
    UR.TotalPosts,
    UR.Questions,
    UR.Answers,
    UR.TotalScore,
    COALESCE(BS.GoldBadges, 0) AS GoldBadges,
    COALESCE(BS.SilverBadges, 0) AS SilverBadges,
    COALESCE(BS.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(TA.TotalAcceptedAnswers, 0) AS TotalAcceptedAnswers,
    COALESCE(TA.AcceptedScore, 0) AS AcceptedScore
FROM 
    UserReputation UR
LEFT JOIN 
    BadgeSummary BS ON UR.UserId = BS.UserId
LEFT JOIN 
    TopAnswers TA ON UR.UserId = TA.OwnerUserId
WHERE 
    UR.Reputation > 1000 
ORDER BY 
    UR.TotalScore DESC, 
    UR.Reputation DESC
LIMIT 10;