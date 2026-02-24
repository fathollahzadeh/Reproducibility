WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(V.BountyAmount) AS TotalBounties
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.Reputation
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViews
    FROM Posts P
    WHERE P.PostTypeId = 2 
    GROUP BY P.OwnerUserId
)
SELECT 
    U.UserId,
    U.Reputation,
    U.BadgeCount,
    COALESCE(PS.AnswerCount, 0) AS AnswerCount,
    COALESCE(PS.TotalScore, 0) AS TotalScore,
    COALESCE(PS.AvgViews, 0) AS AvgViews,
    U.TotalBounties
FROM UserStats U
LEFT JOIN PostStats PS ON U.UserId = PS.OwnerUserId
ORDER BY U.Reputation DESC, U.BadgeCount DESC;