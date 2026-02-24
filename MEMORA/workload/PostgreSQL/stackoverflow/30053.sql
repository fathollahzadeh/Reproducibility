
WITH RECURSIVE UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(v.Id), 0) AS TotalVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.Reputation, u.DisplayName
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(ph.RevisionCount, 0) AS RevisionCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS RevisionCount FROM PostHistory GROUP BY PostId) ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '30 days'
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        RANK() OVER (ORDER BY ua.TotalVotes DESC) AS UserRank
    FROM 
        UserActivity ua
    WHERE 
        ua.TotalVotes > 0
)
SELECT 
    pu.PostId,
    pu.Title,
    pu.Score,
    pu.ViewCount,
    pu.CommentCount,
    pu.RevisionCount,
    tu.DisplayName AS TopUser,
    tu.Reputation AS UserReputation,
    pu.PostRank,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pu.PostId AND v.VoteTypeId = 2) AS PostUpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pu.PostId AND v.VoteTypeId = 3) AS PostDownVotes
FROM 
    PostMetrics pu
JOIN 
    TopUsers tu ON pu.PostRank <= 10
ORDER BY 
    pu.PostRank;
