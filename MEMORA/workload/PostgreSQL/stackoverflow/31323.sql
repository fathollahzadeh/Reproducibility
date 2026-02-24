WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostVotes AS (
    SELECT 
        v.PostId, 
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(DISTINCT p.Id) AS PostsCount, 
        COUNT(DISTINCT c.Id) AS CommentsCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        ua.UserId, 
        ua.PostsCount, 
        ua.CommentsCount,
        RANK() OVER (ORDER BY ua.PostsCount DESC) AS UserRank
    FROM 
        UserActivity ua
)
SELECT 
    rp.PostId, 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(pv.UpVotes, 0) AS UpVotes,
    COALESCE(pv.DownVotes, 0) AS DownVotes,
    tu.UserId,
    tu.PostsCount,
    tu.CommentsCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVotes pv ON rp.PostId = pv.PostId
LEFT JOIN 
    Posts p ON rp.PostId = p.Id
JOIN 
    TopUsers tu ON p.OwnerUserId = tu.UserId
WHERE 
    rp.Rank <= 5
    AND (p.ClosedDate IS NULL OR p.ClosedDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month')
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;