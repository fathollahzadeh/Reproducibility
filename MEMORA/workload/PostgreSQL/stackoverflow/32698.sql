WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
        AND p.Score > 0
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        b.Class AS BadgeClass,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, b.Class
),
PostRecentHistory AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS LastEditDate,
        ph.PostHistoryTypeId,
        CONCAT(u.DisplayName, ' edited this post.') AS EditComment
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.CreationDate = (
            SELECT MAX(CreationDate)
            FROM PostHistory 
            WHERE PostId = p.Id
        )
),
PostVoteStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId IN (2, 4) THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId IN (3, 12) THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerUserId,
    ub.BadgeCount,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    ph.LastEditDate,
    ph.EditComment
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
LEFT JOIN 
    PostVoteStats vs ON rp.PostId = vs.PostId
LEFT JOIN 
    PostRecentHistory ph ON rp.PostId = ph.PostId
WHERE 
    rp.UserPostRank = 1
    AND ub.BadgeClass = 1  
ORDER BY 
    rp.Score DESC;