
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AcceptedAnswerId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank,
        COALESCE(u.Reputation, 0) AS UserReputation,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
), RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Badges b
    WHERE 
        b.Class = 1 AND b.Date >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '6 months')
    GROUP BY 
        b.UserId
), TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.UserReputation,
        rb.BadgeCount,
        ROW_NUMBER() OVER (ORDER BY rp.ViewCount DESC) AS TopRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentBadges rb ON rp.OwnerUserId = rb.UserId
    WHERE 
        rp.ViewRank <= 10 AND (rb.BadgeCount IS NULL OR rb.BadgeCount > 0)
)
SELECT 
    tp.Title,
    tp.UserReputation,
    COALESCE(tp.BadgeCount, 0) AS BadgeCount,
    (SELECT COUNT(c.Id) 
     FROM Comments c 
     WHERE c.PostId = tp.PostId) AS CommentCount,
    (SELECT COUNT(v.Id)
     FROM Votes v
     WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2) AS UpvoteCount,
    CASE 
        WHEN tp.BadgeCount IS NULL THEN 'No Badges'
        WHEN tp.BadgeCount >= 1 THEN 'Has Badges'
        ELSE 'Unknown'
    END AS BadgeStatus
FROM 
    TopPosts tp
WHERE 
    tp.TopRank < 11 AND 
    (1 = 1 OR EXISTS (
        SELECT 1 
        FROM Votes v 
        WHERE v.PostId = tp.PostId AND v.VoteTypeId IN (2, 3)
        GROUP BY v.PostId
        HAVING COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) > COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END)
    ))
ORDER BY 
    tp.UserReputation DESC NULLS LAST, 
    tp.BadgeCount DESC;
