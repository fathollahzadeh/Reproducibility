
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        (SELECT 
            COUNT(DISTINCT b.Id) 
         FROM 
            Badges b 
         WHERE 
            b.UserId = p.OwnerUserId) AS UserBadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
PostStatistics AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.PostRank,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.UserBadgeCount,
        CASE 
            WHEN rp.Score > 100 THEN 'Highly Active'
            WHEN rp.Score BETWEEN 50 AND 100 THEN 'Moderately Active'
            ELSE 'Low Activity'
        END AS ActivityLevel
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentCount > 5 OR (rp.UpVotes - rp.DownVotes) > 10
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalPoints,
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalPoints DESC
    LIMIT 10
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ActivityLevel,
    tu.DisplayName,
    tu.TotalPoints,
    tu.PostsCount,
    COALESCE((SELECT 
                STRING_AGG(c.Text, '; ') 
               FROM 
                Comments c 
               WHERE 
                c.PostId = ps.PostId), 'No comments') AS CommentsSummary
FROM 
    PostStatistics ps
JOIN 
    TopUsers tu ON ps.UpVotes > 2 * ps.DownVotes
ORDER BY 
    ps.Score DESC, ps.CreationDate DESC;
