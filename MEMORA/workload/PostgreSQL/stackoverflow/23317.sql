
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COALESCE(SUM(CASE WHEN vt.Id = 2 THEN 1 ELSE 0 END), 0) AS Upvotes, 
        COALESCE(SUM(CASE WHEN vt.Id = 3 THEN 1 ELSE 0 END), 0) AS Downvotes, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.OwnerUserId, p.CreationDate
),
UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount, 
        MAX(b.Class) AS HighestBadgeClass 
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId, 
        COUNT(ph.Id) AS EditCount, 
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
),
DistinctTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS UniqueTagCount
    FROM 
        Posts p
    JOIN 
        Tags t ON t.WikiPostId = p.Id
    GROUP BY 
        p.Id
)
SELECT 
    up.DisplayName,
    up.Reputation,
    p.Title,
    p.ViewCount,
    p.Score,
    phd.EditCount,
    pt.UniqueTagCount,
    ub.BadgeCount AS TotalBadges,
    ub.HighestBadgeClass,
    CASE 
        WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CASE 
        WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted Answer Exists'
        ELSE 'No Accepted Answer'
    END AS AnswerStatus
FROM 
    Users up
JOIN 
    Posts p ON up.Id = p.OwnerUserId
LEFT JOIN 
    PostHistoryDetails phd ON p.Id = phd.PostId
LEFT JOIN 
    DistinctTagCounts pt ON p.Id = pt.PostId
LEFT JOIN 
    UserBadgeCounts ub ON up.Id = ub.UserId
WHERE 
    up.Reputation > 100 AND
    p.ViewCount IS NOT NULL AND
    (p.Score > 0 OR p.ViewCount > 100) 
ORDER BY 
    CASE 
        WHEN ub.HighestBadgeClass = 1 THEN 1 
        WHEN ub.HighestBadgeClass = 2 THEN 2 
        ELSE 3 
    END, 
    p.Score DESC;
