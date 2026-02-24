
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount,
        AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteRatio
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.PostTypeId, p.Score, p.ViewCount
), CTE_BadgedUsers AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), PopularPosts AS (
    SELECT 
        rp.*,
        u.DisplayName,
        ub.BadgeCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        CTE_BadgedUsers ub ON u.Id = ub.UserId
    WHERE 
        rp.RankScore <= 10
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.DisplayName,
    pp.Score,
    pp.ViewCount,
    COALESCE(pp.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN pp.UpVoteRatio IS NULL THEN 'No Votes'
        WHEN pp.UpVoteRatio > 0.5 THEN 'Predominantly Upvoted'
        ELSE 'Mixed Votes'
    END AS VoteStatus
FROM 
    PopularPosts pp
WHERE 
    pp.PostTypeId = 1 
ORDER BY 
    pp.Score DESC, pp.CreationDate DESC;
