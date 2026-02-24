
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END, 0)) AS UpVotes,
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000
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
        RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserReputation
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.PostCount,
    T.UpVotes,
    T.DownVotes,
    T.Rank,
    COALESCE(AVG(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
    COALESCE(AVG(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
    COALESCE(AVG(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
FROM 
    TopUsers T
LEFT JOIN 
    Badges B ON T.UserId = B.UserId
WHERE 
    T.Rank <= 10
GROUP BY 
    T.UserId, T.DisplayName, T.Reputation, T.PostCount, T.UpVotes, T.DownVotes, T.Rank
ORDER BY 
    T.Rank;
