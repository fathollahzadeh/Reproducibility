WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation
),
VoteStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(V.UpVotes, 0) AS UpVotes,
        COALESCE(V.DownVotes, 0) AS DownVotes,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        VoteStats V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        R.Reputation,
        R.PostCount
    FROM 
        Users U
    JOIN 
        UserReputation R ON U.Id = R.UserId
    WHERE 
        R.Reputation > 1000
    ORDER BY 
        R.Reputation DESC
    LIMIT 10
)

SELECT 
    U.DisplayName AS TopUser,
    P.Title AS PostTitle,
    P.CreationDate AS PostDate,
    P.UpVotes,
    P.DownVotes,
    P.CommentCount,
    CASE 
        WHEN P.UpVotes - P.DownVotes > 0 THEN 'Positive'
        WHEN P.UpVotes - P.DownVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    (SELECT STRING_AGG(Name, ', ') 
     FROM Badges B 
     WHERE B.UserId = U.Id
     GROUP BY B.UserId) AS Badges
FROM 
    TopUsers U
JOIN 
    PostMetrics P ON U.Id = P.PostId
WHERE 
    P.CommentCount > 5
ORDER BY 
    P.UpVotes DESC, 
    P.CommentCount DESC;