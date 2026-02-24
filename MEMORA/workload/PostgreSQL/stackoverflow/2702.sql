
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (DATE '2024-10-01' - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Badges b
    WHERE 
        b.Date >= (DATE '2024-10-01' - INTERVAL '6 months')
    GROUP BY 
        b.UserId
),
VoteStats AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rb.BadgeCount AS RecentBadges,
    vs.UpVoteCount,
    vs.DownVoteCount
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentBadges rb ON rb.UserId = (SELECT p.OwnerUserId FROM Posts p WHERE p.Id = rp.PostId)
LEFT JOIN 
    VoteStats vs ON vs.PostId = rp.PostId
WHERE 
    rp.UserRank <= 5
ORDER BY 
    rp.Score DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
