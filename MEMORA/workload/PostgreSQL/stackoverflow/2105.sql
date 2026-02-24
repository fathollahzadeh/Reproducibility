
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(
            (SELECT AVG(Score) 
             FROM Posts p2 
             WHERE p2.PostTypeId = p.PostTypeId), 0) AS AvgScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Rank,
        rp.Score,
        rp.ViewCount,
        rp.AvgScore,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    u.DisplayName AS PostOwner,
    ua.Upvotes,
    ua.Downvotes,
    ua.TotalPosts,
    ua.TotalComments
FROM 
    TopPosts tp
LEFT JOIN 
    Users u ON tp.PostId = u.Id
LEFT JOIN 
    UserActivity ua ON u.Id = ua.UserId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
