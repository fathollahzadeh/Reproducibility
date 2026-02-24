
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.Views,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation, u.Views
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        Views,
        PostCount,
        CommentCount,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        RANK() OVER (ORDER BY Views DESC) AS ViewsRank
    FROM 
        UserStats
)
SELECT 
    UserId,
    Reputation,
    Views,
    PostCount,
    CommentCount,
    UpVotes,
    DownVotes,
    ReputationRank,
    ViewsRank
FROM 
    TopUsers
WHERE 
    ReputationRank <= 10 OR ViewsRank <= 10
ORDER BY 
    ReputationRank, ViewsRank;
