
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(SUM(CASE WHEN b.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS BadgeCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount
), PostAnalytics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Upvotes,
        rp.Downvotes,
        rp.BadgeCount,
        (rp.Upvotes - rp.Downvotes) AS Score,
        CASE 
            WHEN rp.BadgeCount > 0 THEN 'Has Badges' 
            ELSE 'No Badges' 
        END AS BadgeStatus
    FROM 
        RankedPosts rp
)
SELECT 
    pa.*,
    pt.Name AS PostTypeName,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = pa.PostId) AS CommentCount
FROM 
    PostAnalytics pa
JOIN 
    PostTypes pt ON pt.Id = (SELECT p.PostTypeId FROM Posts p WHERE p.Id = pa.PostId LIMIT 1)
WHERE 
    pa.Score > 0
ORDER BY 
    pa.Score DESC, pa.ViewCount DESC
LIMIT 100;
