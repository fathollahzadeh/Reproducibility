
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS OverallRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserBadges AS (
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
),
ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseHistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    up.BadgeCount,
    up.BadgeNames,
    cd.CloseReason,
    COALESCE(pvs.UpVotesCount, 0) AS TotalUpVotes,
    COALESCE(pvs.DownVotesCount, 0) AS TotalDownVotes,
    (rp.CommentCount * GREATEST(COALESCE(pvs.UpVotesCount, 0), 1)) / NULLIF(RP.RankByUser, 0) AS EngagementScore,
    CASE 
        WHEN rp.RankByUser = 1 THEN 'Most Recent Post by User'
        WHEN rp.RankByUser > 1 AND cd.CloseHistoryRank = 1 THEN 'Recently Closed Post'
        ELSE 'Other Post Activity'
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges up ON rp.PostId = up.UserId
LEFT JOIN 
    ClosedPostDetails cd ON rp.PostId = cd.PostId
LEFT JOIN 
    PostVoteStats pvs ON rp.PostId = pvs.PostId
WHERE 
    rp.CommentCount > 5 
    OR up.BadgeCount > 1
ORDER BY 
    EngagementScore DESC NULLS LAST, 
    rp.Score DESC;
