WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(P.Score) AS AverageScore
    FROM 
        Users U 
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        UpVotes,
        DownVotes,
        AverageScore,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, AverageScore DESC) AS `Rank`
    FROM 
        UserActivity
)
SELECT 
    T.UserId,
    T.DisplayName,
    T.Reputation,
    T.PostCount,
    T.UpVotes,
    T.DownVotes,
    T.AverageScore,
    COALESCE(B.Count, 0) AS BadgeCount,
    CASE 
        WHEN T.Reputation > 1000 THEN 'Experienced'
        WHEN T.Reputation > 500 THEN 'Moderate'
        ELSE 'Novice'
    END AS UserLevel
FROM 
    TopUsers T
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS `Count` 
     FROM Badges 
     GROUP BY UserId) B ON T.UserId = B.UserId
WHERE 
    T.Rank <= 10
ORDER BY 
    T.AverageScore DESC, T.PostCount DESC;
