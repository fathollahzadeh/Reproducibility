
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        CommentCount,
        UpVoteCount,
        DownVoteCount,
        RANK() OVER (ORDER BY PostCount DESC, UpVoteCount DESC) AS Rank
    FROM 
        UserPostStats
)
SELECT 
    UserId, 
    Reputation, 
    PostCount, 
    CommentCount, 
    UpVoteCount, 
    DownVoteCount
FROM 
    TopUsers
WHERE 
    Rank <= 10;
