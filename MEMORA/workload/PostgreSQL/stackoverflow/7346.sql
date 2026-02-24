
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.Reputation, U.DisplayName, U.Views, U.UpVotes, U.DownVotes
),
TopTags AS (
    SELECT 
        T.TagName,
        COUNT(PL.PostId) AS LinkCount
    FROM Tags T
    JOIN PostLinks PL ON T.Id = PL.RelatedPostId
    GROUP BY T.TagName
    ORDER BY LinkCount DESC
    LIMIT 10
),
PopularBadges AS (
    SELECT 
        B.Name,
        COUNT(B.Id) AS BadgeCount,
        U.Id AS UserId
    FROM Badges B
    JOIN Users U ON B.UserId = U.Id
    GROUP BY B.Name, U.Id
    ORDER BY BadgeCount DESC
    LIMIT 5
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.Views,
    US.TotalPosts,
    US.TotalQuestions,
    US.TotalAnswers,
    US.TotalScore,
    TT.TagName,
    PB.Name AS PopularBadge
FROM UserStats US
CROSS JOIN TopTags TT
LEFT JOIN PopularBadges PB ON US.UserId = PB.UserId
WHERE US.Reputation > 1000
ORDER BY US.Reputation DESC, US.TotalScore DESC;
