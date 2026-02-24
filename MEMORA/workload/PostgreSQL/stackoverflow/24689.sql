WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        p.Id
),

PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.Comment END) AS ClosureReason
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),

BadgedUsers AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    CASE 
      WHEN phi.ClosedDate IS NOT NULL THEN 'Closed'
      ELSE 'Open'
    END AS PostStatus,
    phi.ClosedDate,
    phi.ClosureReason,
    bu.BadgeCount,
    bu.BadgeNames
FROM
    RankedPosts rp
LEFT JOIN 
    PostHistoryInfo phi ON rp.PostId = phi.PostId
LEFT JOIN 
    BadgedUsers bu ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = bu.UserId)
WHERE 
    rp.Rank <= 5
ORDER BY 
    COALESCE(rp.Score, 0) DESC, rp.CreationDate DESC;