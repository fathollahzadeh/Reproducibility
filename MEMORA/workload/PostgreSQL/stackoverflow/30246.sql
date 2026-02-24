
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankViewCount,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '2 years'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        b.UserId
),
ClosedPosts AS (
    SELECT 
        p.Id,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        ph.PostId
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
),
MergedQuestions AS (
    SELECT 
        p1.Id AS MergedPostId,
        p2.Id AS OriginalPostId,
        ph.CreationDate
    FROM 
        Posts p1
    INNER JOIN 
        PostHistory ph ON p1.Id = ph.PostId 
    INNER JOIN 
        Posts p2 ON p2.AcceptedAnswerId = p1.Id
    WHERE 
        ph.PostHistoryTypeId = 38  
)
SELECT 
    up.Id AS UserId,
    up.DisplayName,
    up.Reputation,
    ub.BadgeCount,
    ub.BadgeNames,
    rp.Title AS TopPostTitle,
    rp.Score AS TopPostScore,
    rp.ViewCount AS TopPostViewCount,
    cp.UserDisplayName AS ClosedBy,
    cp.CreationDate AS ClosedDate,
    mq.OriginalPostId AS MergedOriginalPostId,
    mq.CreationDate AS MergedQuestionDate
FROM 
    Users up
LEFT JOIN 
    UserBadges ub ON up.Id = ub.UserId
LEFT JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId AND rp.RankScore = 1
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = rp.Id
LEFT JOIN 
    MergedQuestions mq ON mq.MergedPostId = rp.Id
WHERE 
    up.Reputation > 1000
ORDER BY 
    up.Reputation DESC, 
    rp.Score DESC;
