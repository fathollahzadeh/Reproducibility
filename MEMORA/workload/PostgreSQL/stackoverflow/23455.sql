WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
        AND p.Score >= (SELECT AVG(Score) FROM Posts WHERE CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days')
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass,
        MIN(b.Date) AS FirstBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
PostEngagement AS (
    SELECT 
        p.Id,
        COALESCE(c.CommentCount, 0) AS TotalComments,
        COALESCE(v.UpVotes, 0) - COALESCE(v.DownVotes, 0) AS NetVotes,
        COUNT(pl.RelatedPostId) AS RelatedLinksCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    GROUP BY 
        p.Id, c.CommentCount, v.UpVotes, v.DownVotes
),
PostHistoryAggregate AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(DISTINCT ph.Id) AS EditCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate > cast('2024-10-01' as date) - INTERVAL '90 days'
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    pe.TotalComments,
    pe.NetVotes,
    ba.BadgeCount,
    ba.HighestBadgeClass,
    pha.HistoryTypes,
    pha.EditCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PostEngagement pe ON rp.PostId = pe.Id
LEFT JOIN 
    UserBadges ba ON rp.OwnerUserId = ba.UserId
LEFT JOIN 
    PostHistoryAggregate pha ON rp.PostId = pha.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.CreationDate DESC, rp.Score DESC;