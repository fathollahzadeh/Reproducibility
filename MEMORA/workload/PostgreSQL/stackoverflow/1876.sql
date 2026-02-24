WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(P.Score) AS TotalScore,
        RANK() OVER (ORDER BY SUM(P.Score) DESC) AS ScoreRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        Questions,
        Answers,
        TotalScore
    FROM UserPostStats
    WHERE ScoreRank <= 10
),
RecentVotes AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS TotalVotes
    FROM Votes V
    WHERE V.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY V.UserId
),
FinalStats AS (
    SELECT 
        TU.*,
        COALESCE(RV.TotalVotes, 0) AS RecentVotes
    FROM TopUsers TU
    LEFT JOIN RecentVotes RV ON TU.UserId = RV.UserId
)
SELECT 
    FS.UserId,
    FS.DisplayName,
    FS.TotalPosts,
    FS.Questions,
    FS.Answers,
    FS.TotalScore,
    FS.RecentVotes,
    CASE 
        WHEN FS.TotalScore > 100 THEN 'High Scorer'
        WHEN FS.TotalScore BETWEEN 50 AND 100 THEN 'Moderate Scorer'
        ELSE 'Low Scorer'
    END AS ScoreCategory
FROM FinalStats FS
ORDER BY FS.TotalScore DESC, FS.RecentVotes DESC
LIMIT 5;