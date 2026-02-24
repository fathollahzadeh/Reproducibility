WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS TotalUpVotes,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS TotalDownVotes,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY COUNT(DISTINCT P.Id) DESC) AS Rank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        TotalViews,
        TotalUpVotes,
        TotalDownVotes,
        DENSE_RANK() OVER (ORDER BY PostCount DESC) AS PostRank
    FROM UserActivity
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.TotalViews,
    TU.TotalUpVotes,
    TU.TotalDownVotes,
    CASE 
        WHEN TU.TotalDownVotes = 0 THEN 'No Negative Feedback'
        ELSE CONCAT('Negative Feedback: ', TU.TotalDownVotes)
    END AS FeedbackStatus,
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = TU.UserId AND B.Class = 1) AS GoldBadges,
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = TU.UserId AND B.Class = 2) AS SilverBadges,
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = TU.UserId AND B.Class = 3) AS BronzeBadges
FROM TopUsers TU
WHERE TU.PostRank <= 10
ORDER BY TU.PostCount DESC;
