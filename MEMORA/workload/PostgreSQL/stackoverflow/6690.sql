
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
        AND p.Score > 0
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        u.LastAccessDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '3 months'
    GROUP BY 
        u.Id
),
TopBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Date >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        b.UserId
    HAVING 
        COUNT(*) >= 5
),
PostInteractions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        ru.UserId,
        ru.PostCount,
        ru.UpVotes,
        ru.DownVotes,
        tb.BadgeCount
    FROM 
        RankedPosts rp
    JOIN 
        ActiveUsers ru ON ru.PostCount > 5
    LEFT JOIN 
        TopBadges tb ON tb.UserId = ru.UserId
)
SELECT 
    pi.PostId,
    pi.Title,
    pi.ViewCount,
    pi.PostCount,
    pi.UpVotes,
    pi.DownVotes,
    COALESCE(pi.BadgeCount, 0) AS BadgeCount
FROM 
    PostInteractions pi
WHERE 
    COALESCE(pi.BadgeCount, 0) >= 1
ORDER BY 
    pi.ViewCount DESC, pi.PostCount DESC;
