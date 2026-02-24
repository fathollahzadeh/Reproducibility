WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0
),
PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(t.Id) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON POSITION(t.TagName IN p.Tags) > 0
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
),
UserReputationHistory AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        MIN(b.Date) AS FirstBadgeDate,
        MAX(b.Date) AS LatestBadgeDate,
        AVG(u.UpVotes - u.DownVotes) AS AvgVoteScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS Author,
    p.ViewCount,
    p.Score,
    pt.TagCount,
    urh.Reputation AS AuthorReputation,
    urh.BadgeCount,
    urh.AvgVoteScore,
    CASE 
        WHEN p.ClosedDate IS NOT NULL THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus,
    CASE 
        WHEN r.rn = 1 THEN 'Top' 
        ELSE CONCAT('Rank ', r.rn, '/', r.TotalPosts) 
    END AS RankInfo
FROM 
    RankedPosts r
JOIN 
    Posts p ON r.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    PostTagCounts pt ON p.Id = pt.PostId
JOIN 
    UserReputationHistory urh ON u.Id = urh.UserId
WHERE 
    urh.BadgeCount > 0
ORDER BY 
    p.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;
