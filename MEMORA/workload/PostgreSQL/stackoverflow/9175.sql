
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId IN (10, 11) THEN 1 ELSE 0 END) AS ClosedPosts,
        AVG(U.Reputation) AS AvgReputation,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS UpVotes,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.CreationDate < CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        Questions,
        Answers,
        ClosedPosts,
        AvgReputation,
        UpVotes - DownVotes AS NetVotes
    FROM 
        UserActivity
    WHERE 
        PostCount > 5
    ORDER BY 
        NetVotes DESC, AvgReputation DESC
    LIMIT 10
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.PostCount,
    U.Questions,
    U.Answers,
    U.ClosedPosts,
    U.AvgReputation,
    U.NetVotes,
    BH.Name AS BadgeName,
    BH.Class
FROM 
    TopUsers U
LEFT JOIN 
    Badges BH ON U.UserId = BH.UserId
ORDER BY 
    U.NetVotes DESC, U.AvgReputation DESC;
