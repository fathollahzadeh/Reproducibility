
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostAnalytics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(DISTINCT P.Id) AS PostCount,
        AVG(P.Score) AS AverageScore,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(DISTINCT CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN P.Id END) AS AcceptedAnswers
    FROM Posts P
    GROUP BY P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.UpVotes,
        U.DownVotes,
        U.GoldBadges,
        U.SilverBadges,
        U.BronzeBadges,
        COALESCE(PA.PostCount, 0) AS PostCount,
        COALESCE(PA.AverageScore, 0) AS AverageScore,
        COALESCE(PA.TotalViews, 0) AS TotalViews,
        COALESCE(PA.AcceptedAnswers, 0) AS AcceptedAnswers
    FROM UserStats U
    LEFT JOIN PostAnalytics PA ON U.UserId = PA.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    UpVotes,
    DownVotes,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    PostCount,
    AverageScore,
    TotalViews,
    AcceptedAnswers,
    ROW_NUMBER() OVER (ORDER BY UpVotes DESC, DownVotes ASC) AS Rank,
    CASE 
        WHEN UpVotes - DownVotes < 0 THEN 'Negative Influence'
        WHEN UpVotes - DownVotes >= 0 AND UpVotes - DownVotes < 10 THEN 'Moderate Influence'
        WHEN UpVotes - DownVotes >= 10 THEN 'Positive Influence'
        ELSE 'Neutral'
    END AS InfluenceType
FROM CombinedStats
WHERE PostCount > 0
ORDER BY TotalViews DESC
FETCH FIRST 10 ROWS ONLY;
