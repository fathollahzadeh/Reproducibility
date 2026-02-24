
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(ph.PostHistoryTypeId, 0) AS LastChangeType,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' 
        AND p.Score >= 0
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score, ph.PostHistoryTypeId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostLinksInfo AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS LinkCount,
        STRING_AGG(DISTINCT lt.Name, ', ') AS LinkTypeNames
    FROM 
        PostLinks pl
    JOIN 
        LinkTypes lt ON pl.LinkTypeId = lt.Id
    GROUP BY 
        pl.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    rp.Score,
    rp.LastChangeType,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    ur.Reputation,
    ur.ReputationRank,
    ub.BadgeCount,
    ub.BadgeNames,
    pli.LinkCount,
    pli.LinkTypeNames
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostLinksInfo pli ON rp.PostId = pli.PostId
WHERE 
    rp.Rank <= 3
    AND (rp.CommentCount > 5 OR ur.Reputation IS NULL)
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
