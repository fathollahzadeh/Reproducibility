WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.CreationDate <= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        CommentCount, 
        UpVotes, 
        DownVotes,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    T.DisplayName,
    T.Reputation,
    T.PostCount,
    T.CommentCount,
    T.UpVotes,
    T.DownVotes,
    T.Rank,
    ARRAY_AGG(DISTINCT TAG.TagName) AS ExpertiseTags
FROM 
    TopUsers T
LEFT JOIN 
    Posts P ON T.UserId = P.OwnerUserId
LEFT JOIN 
    LATERAL (SELECT unnest(string_to_array(P.Tags, '<>')) AS TagName) TAG ON TRUE
WHERE 
    T.Rank <= 10
GROUP BY 
    T.UserId, T.DisplayName, T.Reputation, T.PostCount, T.CommentCount, T.UpVotes, T.DownVotes, T.Rank
ORDER BY 
    T.Rank;