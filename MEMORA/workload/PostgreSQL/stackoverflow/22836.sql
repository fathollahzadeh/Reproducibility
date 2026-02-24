
WITH UserReputation AS (
    SELECT 
        Id,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        Users
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(*) AS TotalEdits
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    ur.ReputationRank,
    tp.PostId,
    tp.Title,
    tp.CreationDate AS PostCreationDate,
    tp.Score,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    COALESCE(phs.CloseCount, 0) AS CloseCount,
    COALESCE(phs.ReopenCount, 0) AS ReopenCount,
    COALESCE(phs.TotalEdits, 0) AS TotalEdits,
    COALESCE(ub.BadgeNames, 'No Badges') AS Badges
FROM 
    Users u
JOIN 
    UserReputation ur ON u.Id = ur.Id
LEFT JOIN 
    TopPosts tp ON u.Id = tp.OwnerUserId
LEFT JOIN 
    PostHistorySummary phs ON tp.PostId = phs.PostId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    u.Reputation > 1000
    AND tp.Score IS NOT NULL
ORDER BY 
    ur.ReputationRank, tp.CommentCount DESC;
