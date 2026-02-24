
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY u.Id ORDER BY COUNT(DISTINCT p.Id) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        UpVotes, 
        DownVotes, 
        CommentCount
    FROM 
        UserActivity
    WHERE 
        Rank <= 10
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title
),
HighScoringPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.TotalComments,
        ps.TotalUpVotes,
        ps.TotalDownVotes,
        RANK() OVER (ORDER BY ps.TotalUpVotes - ps.TotalDownVotes DESC) AS PostRank
    FROM 
        PostStats ps
    WHERE 
        ps.TotalUpVotes > 0
)

SELECT 
    t.DisplayName,
    t.PostCount,
    t.UpVotes,
    t.DownVotes,
    t.CommentCount,
    h.PostId,
    h.Title,
    h.TotalComments,
    h.TotalUpVotes,
    h.TotalDownVotes
FROM 
    TopUsers t
LEFT JOIN 
    HighScoringPosts h ON t.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = h.PostId)
WHERE 
    h.PostRank <= 5
ORDER BY 
    t.UpVotes DESC, h.TotalUpVotes - h.TotalDownVotes DESC;
