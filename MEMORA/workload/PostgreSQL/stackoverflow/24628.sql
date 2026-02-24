
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(v.UpVotes, 0) AS TotalUpVotes,
        COALESCE(v.DownVotes, 0) AS TotalDownVotes
    FROM 
        Posts p
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
    WHERE 
        p.CreationDate >= DATE('2024-10-01') - INTERVAL '1 year'
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(COALESCE(v.TotalUpVotes, 0) - COALESCE(v.TotalDownVotes, 0)) AS VoteScore,
        AVG(EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - u.CreationDate)) / 3600) AS AvgHoursSinceCreation
    FROM 
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN (
        SELECT 
            p.OwnerUserId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
        FROM 
            Posts p
        JOIN Votes v ON p.Id = v.PostId
        GROUP BY p.OwnerUserId
    ) v ON u.Id = v.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS LastClosedOrReopened,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount
    FROM 
        PostHistory ph
    GROUP BY ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    um.DisplayName AS OwnerName,
    um.BadgeCount,
    um.VoteScore,
    pha.LastClosedOrReopened,
    pha.DeleteCount,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Latest Post by User'
        WHEN rp.PostRank <= 5 THEN 'Top 5 Recent Posts'
        ELSE 'Older Posts'
    END AS PostCategory
FROM 
    RankedPosts rp
JOIN 
    UserMetrics um ON rp.OwnerUserId = um.UserId
LEFT JOIN 
    PostHistoryAggregates pha ON rp.PostId = pha.PostId
WHERE 
    um.VoteScore > 0
ORDER BY 
    um.VoteScore DESC, rp.CreationDate DESC;
