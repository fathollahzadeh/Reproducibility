WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        Questions,
        Answers,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY PostCount DESC, UpVotes - DownVotes DESC) AS EngagementRank
    FROM UserEngagement
)
SELECT 
    TU.DisplayName,
    TU.PostCount,
    TU.Questions,
    TU.Answers,
    TU.UpVotes,
    TU.DownVotes,
    CASE 
        WHEN TU.PostCount > 50 THEN 'Highly Active' 
        WHEN TU.PostCount BETWEEN 20 AND 50 THEN 'Moderately Active' 
        ELSE 'Less Active' 
    END AS ActivityLevel
FROM TopUsers TU
WHERE TU.EngagementRank <= 10
ORDER BY TU.PostCount DESC, TU.UpVotes - TU.DownVotes DESC;
