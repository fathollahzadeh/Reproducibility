WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        AVG(COALESCE(P.Score, 0)) AS AvgPostScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        PostCount,
        AvgPostScore,
        RANK() OVER (ORDER BY PostCount DESC, AvgPostScore DESC) AS UserRank
    FROM UserVoteStats
)
SELECT 
    T.DisplayName,
    T.UpVotes,
    T.DownVotes,
    T.PostCount,
    T.AvgPostScore,
    CASE 
        WHEN T.UserRank <= 10 THEN 'Top Contributor'
        ELSE 'Contributor'
    END AS UserCategory,
    (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = T.UserId AND CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days') AS RecentPosts,
    (SELECT COUNT(*) FROM Badges B WHERE B.UserId = T.UserId AND B.Class = 1) AS GoldBadges,
    COALESCE(CAST(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS INTEGER), 0) AS SilverBadges,
    COALESCE(CAST(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS INTEGER), 0) AS BronzeBadges
FROM TopUsers T
LEFT JOIN Badges B ON T.UserId = B.UserId
WHERE T.PostCount > 0
GROUP BY T.UserId, T.DisplayName, T.UpVotes, T.DownVotes, T.PostCount, T.AvgPostScore, T.UserRank
ORDER BY T.UserRank;