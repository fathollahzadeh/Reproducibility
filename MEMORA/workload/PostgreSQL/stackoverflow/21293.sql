WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rk,
        ARRAY_AGG(DISTINCT t.TagName) AS tags
    FROM 
        Posts p
    JOIN 
        UNNEST(string_to_array(trim(both '{}' FROM p.Tags), '><')) AS t(TagName) ON true
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        MAX(b.Date) AS LastBadgeDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.Id
    LEFT JOIN 
        Badges b ON b.UserId = rp.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = rp.Id
    WHERE 
        rp.rk <= 5
    GROUP BY 
        rp.Id, rp.Title, rp.Score, rp.ViewCount, rp.OwnerUserId
),
PostStats AS (
    SELECT 
        Top.*, 
        CASE 
            WHEN LastBadgeDate IS NOT NULL THEN 'Active User' 
            ELSE 'No Active Badges' 
        END AS BadgeStatus,
        CASE 
            WHEN UpVoteCount > 5 THEN 'Highly Valued'
            WHEN UpVoteCount BETWEEN 1 AND 5 THEN 'Moderately Valued'
            ELSE 'Needs Attention'
        END AS ValueCategory
    FROM 
        TopPosts Top
)
SELECT 
    ps.Id,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.BadgeStatus,
    ps.ValueCategory,
    (SELECT MAX(CreationDate) 
     FROM PostHistory ph 
     WHERE ph.PostId = ps.Id 
       AND ph.PostHistoryTypeId IN (10, 11)) AS LastClosedOrReopened
FROM 
    PostStats ps
WHERE 
    ps.OwnerUserId IS NOT NULL
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 50;