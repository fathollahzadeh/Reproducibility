
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 500
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        Reputation,
        CreationDate,
        LastAccessDate,
        PostCount,
        CommentCount,
        UpVoteCount,
        DownVoteCount,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    U.DisplayName, 
    U.Reputation, 
    U.PostCount, 
    U.CommentCount,
    U.UpVoteCount, 
    U.DownVoteCount,
    (U.UpVoteCount - U.DownVoteCount) AS NetVote,
    CASE 
        WHEN U.Rank <= 10 THEN 'Top Contributor'
        WHEN U.Rank <= 50 THEN 'High Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorLevel
FROM 
    TopUsers U
WHERE 
    U.Rank <= 100
ORDER BY 
    U.Reputation DESC, U.PostCount DESC;
