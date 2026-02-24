
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COUNT(v.Id) FILTER(WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVotes,
        COUNT(v.Id) FILTER(WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
PostBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN pht.Name = 'Initial Body' THEN ph.CreationDate END) AS BodyEditDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.Rank,
    rp.CommentCount,
    COALESCE(bc.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(bc.BadgeNames, 'No Badges') AS UserBadges,
    phd.ClosedDate,
    phd.BodyEditDate,
    CASE 
        WHEN rp.UpVotes > 0 THEN 'Popular'
        WHEN rp.DownVotes > 0 THEN 'Controversial'
        ELSE 'Neutral'
    END AS PopularityStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostBadgeCounts bc ON rp.OwnerUserId = bc.UserId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    rp.Rank = 1
ORDER BY 
    rp.Score DESC,
    rp.CreationDate ASC;
