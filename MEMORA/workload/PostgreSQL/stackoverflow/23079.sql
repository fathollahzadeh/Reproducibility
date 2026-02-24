
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months' 
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount
),
UserBadges AS (
    SELECT 
        b.UserId, 
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryWithReasons AS (
    SELECT 
        ph.PostId, 
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS CloseReason,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.Comment END) AS ReopenReason
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName AS UserDisplayName,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    ub.BadgeNames,
    phwr.CloseReason,
    phwr.ReopenReason
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.PostId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostHistoryWithReasons phwr ON rp.PostId = phwr.PostId
WHERE 
    rp.rn = 1
    AND rp.Score > 10
    AND (rp.CommentCount IS NULL OR rp.CommentCount < 5)
ORDER BY 
    rp.ViewCount DESC,
    rp.Score DESC
LIMIT 100 OFFSET 0;
