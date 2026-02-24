
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 100 
    GROUP BY 
        U.Id, U.Reputation, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        DisplayName,
        PostCount,
        CommentCount,
        UpVotes,
        DownVotes,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserReputation
)
SELECT 
    RU.UserRank,
    RU.DisplayName,
    RU.PostCount,
    RU.CommentCount,
    COALESCE(NULLIF(RU.UpVotes, 0), 1) AS EffectiveUpVotes, 
    COALESCE(NULLIF(RU.DownVotes, 0), 1) AS EffectiveDownVotes,
    CASE 
        WHEN RU.UpVotes > RU.DownVotes THEN 'Positive Influencer'
        WHEN RU.UpVotes < RU.DownVotes THEN 'Negative Influencer'
        ELSE 'Balanced User'
    END AS InfluenceType,
    STDDEV(RU.Reputation) OVER () AS StdDevReputation 
FROM 
    TopUsers RU
WHERE 
    RU.UserRank <= 10 
ORDER BY 
    RU.UserRank;
