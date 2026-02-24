
WITH UserBadgeCounts AS (
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
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    UBC.BadgeCount,
    PS.PostCount,
    PS.QuestionCount,
    PS.AnswerCount,
    PS.TotalScore,
    PS.TotalViews,
    U.CreationDate,
    U.LastAccessDate,
    U.Location
FROM 
    UserBadgeCounts UBC
JOIN 
    Users U ON UBC.UserId = U.Id
JOIN 
    PostStats PS ON U.Id = PS.OwnerUserId
WHERE 
    UBC.BadgeCount > 0 
ORDER BY 
    U.Reputation DESC, 
    PS.TotalScore DESC
LIMIT 10;
