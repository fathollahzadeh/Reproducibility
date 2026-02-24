
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVoteCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
), 
PostBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY b.UserId
),
CommentedPosts AS (
    SELECT
        c.PostId, 
        COUNT(*) AS CommentCount
    FROM 
        Comments c
    GROUP BY c.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.UpVoteCount,
    rp.DownVoteCount,
    COALESCE(cp.CommentCount, 0) AS TotalComments,
    CASE 
        WHEN rp.Score > 100 THEN 'Popular'
        WHEN rp.Score BETWEEN 50 AND 100 THEN 'Moderate'
        ELSE 'Less Known'
    END AS Popularity,
    COALESCE(bc.GoldBadges, 0) AS GoldBadges,
    COALESCE(bc.SilverBadges, 0) AS SilverBadges,
    COALESCE(bc.BronzeBadges, 0) AS BronzeBadges
FROM 
    RankedPosts rp
LEFT JOIN 
    CommentedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    PostBadgeCounts bc ON rp.PostId IN (
        SELECT 
            DISTINCT p.OwnerUserId 
        FROM 
            Posts p
        WHERE 
            p.Score > 0
    )
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.PostId ASC;
