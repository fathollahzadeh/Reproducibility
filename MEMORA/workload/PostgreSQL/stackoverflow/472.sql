
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(P.Score) AS AvgScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        UpVotes,
        DownVotes,
        AvgScore,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, AvgScore DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    T.DisplayName,
    T.PostCount,
    T.UpVotes,
    T.DownVotes,
    T.AvgScore,
    PH.Comment AS RecentActivity
FROM 
    TopUsers T
LEFT JOIN 
    PostHistory PH ON T.UserId = PH.UserId AND PH.CreationDate = (
        SELECT MAX(PH2.CreationDate)
        FROM PostHistory PH2
        WHERE PH2.UserId = T.UserId
    )
WHERE 
    T.Rank <= 10
ORDER BY 
    T.Rank;
