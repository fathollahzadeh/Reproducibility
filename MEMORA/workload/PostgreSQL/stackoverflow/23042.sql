WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UsersWithHighActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 10
),
PostsWithPublicComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    WHERE 
        c.UserId IS NOT NULL
    GROUP BY 
        c.PostId
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(upa.UpvoteCount, 0) - COALESCE(dpa.DownvoteCount, 0) AS ScoreDifference
    FROM 
        Users u
    LEFT JOIN 
        (SELECT UserId, COUNT(*) AS UpvoteCount FROM Votes WHERE VoteTypeId = 2 GROUP BY UserId) upa ON u.Id = upa.UserId
    LEFT JOIN 
        (SELECT UserId, COUNT(*) AS DownvoteCount FROM Votes WHERE VoteTypeId = 3 GROUP BY UserId) dpa ON u.Id = dpa.UserId
    WHERE 
        u.Reputation IS NOT NULL 
        AND (u.Location IS NULL OR u.Location <> '')
)
SELECT 
    up.DisplayName,
    rp.Title,
    rp.Score,
    ca.CommentCount,
    au.ScoreDifference
FROM 
    RankedPosts rp
JOIN 
    UsersWithHighActivity up ON rp.OwnerUserId = up.UserId
LEFT JOIN 
    PostsWithPublicComments ca ON rp.Id = ca.PostId
JOIN 
    ActiveUsers au ON up.UserId = au.Id
WHERE 
    rp.Rank = 1
    AND (rp.Score > (SELECT AVG(Score) FROM Posts) OR ca.CommentCount >= 5)
ORDER BY 
    rp.Score DESC, up.PostCount DESC
LIMIT 100;