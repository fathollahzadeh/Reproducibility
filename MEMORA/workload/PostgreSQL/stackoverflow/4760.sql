WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8  
    GROUP BY U.Id, U.DisplayName
),

UserBadgeCounts AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
),

PostClosureStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS ClosedPostCount
    FROM Posts P
    WHERE P.ClosedDate IS NOT NULL
    GROUP BY P.OwnerUserId
)

SELECT 
    U.DisplayName,
    UPS.PostCount,
    UPS.QuestionCount,
    UPS.AnswerCount,
    COALESCE(UBC.GoldBadges, 0) AS GoldBadges,
    COALESCE(UBC.SilverBadges, 0) AS SilverBadges,
    COALESCE(UBC.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(PCS.ClosedPostCount, 0) AS ClosedPostCount,
    UPS.TotalBounty
FROM Users U
LEFT JOIN UserPostStats UPS ON U.Id = UPS.UserId
LEFT JOIN UserBadgeCounts UBC ON U.Id = UBC.UserId
LEFT JOIN PostClosureStats PCS ON U.Id = PCS.OwnerUserId
WHERE (UPS.PostCount > 5 OR UPS.TotalBounty > 0)
AND U.Reputation > 100
ORDER BY UPS.PostCount DESC, UPS.TotalBounty DESC
LIMIT 10;