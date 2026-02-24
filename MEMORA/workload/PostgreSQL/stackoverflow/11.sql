
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT P.Id) AS QuestionCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.AnswerCount,
        P.ViewCount,
        COALESCE((SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id), 0) AS CommentCount,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentRank,
        P.OwnerUserId
    FROM 
        Posts P
    WHERE 
        P.ClosedDate IS NULL
), UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)

SELECT 
    UR.UserId,
    UR.DisplayName,
    UR.Reputation,
    UR.Upvotes,
    UR.Downvotes,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
    COUNT(DISTINCT PS.PostId) AS TotalQuestions,
    SUM(PS.Score) AS TotalScore,
    AVG(PS.ViewCount) AS AverageViewCount,
    SUM(CASE WHEN PS.RecentRank <= 5 THEN 1 ELSE 0 END) AS RecentHighActivityCount
FROM 
    UserReputation UR
LEFT JOIN 
    UserBadges UB ON UR.UserId = UB.UserId
LEFT JOIN 
    PostStats PS ON UR.UserId = PS.OwnerUserId
GROUP BY 
    UR.UserId, UR.DisplayName, UR.Reputation, UR.Upvotes, UR.Downvotes, 
    UB.GoldBadges, UB.SilverBadges, UB.BronzeBadges
HAVING 
    SUM(PS.Score) > 100
ORDER BY 
    UR.Reputation DESC, TotalScore DESC
LIMIT 100;
