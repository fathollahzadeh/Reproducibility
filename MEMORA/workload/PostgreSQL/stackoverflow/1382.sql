
WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.OwnerUserId, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), PopularUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS post_count,
        COALESCE(SUM(v.BountyAmount), 0) AS total_bounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), RecentComments AS (
    SELECT 
        c.PostId, 
        COUNT(c.Id) AS comment_count
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
    GROUP BY 
        c.PostId
), PostStats AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        COALESCE(rc.comment_count, 0) AS comment_count,
        u.DisplayName AS owner_display_name,
        rp.OwnerUserId
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        RecentComments rc ON rp.Id = rc.PostId
    WHERE 
        rp.rn = 1
)
SELECT 
    ps.Id,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.comment_count,
    pu.DisplayName AS popular_user_name,
    pu.Reputation AS popular_user_reputation,
    pu.post_count,
    pu.total_bounty
FROM 
    PostStats ps
LEFT JOIN 
    PopularUsers pu ON ps.OwnerUserId = pu.Id
ORDER BY 
    ps.Score DESC,
    ps.ViewCount DESC
LIMIT 10;
