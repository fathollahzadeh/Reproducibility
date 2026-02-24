WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.Views,
        u.UpVotes,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE NULL END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN p.Score ELSE 0 END), 0) AS TotalQuestionScore,
        COUNT(DISTINCT CASE WHEN b.Id IS NOT NULL THEN b.Id END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.Views, u.UpVotes
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        pt.Name AS PostTypeName,
        p.Title,
        p.OwnerUserId,
        COUNT(ph.Id) AS CloseCount
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        pt.Name = 'Post Closed'
    GROUP BY 
        ph.PostId, ph.CreationDate, pt.Name, p.Title, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.Reputation,
        us.Views,
        us.AnswerCount,
        RANK() OVER (ORDER BY us.Reputation DESC) AS Rank
    FROM 
        UserStatistics us
    WHERE 
        us.Views > (SELECT AVG(Views) FROM Users)
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    u.DisplayName AS OwnerDisplayName,
    us.Reputation AS OwnerReputation,
    us.Views AS OwnerViews,
    us.AnswerCount AS OwnerAnswerCount,
    cp.CloseCount AS PostCloseCount,
    CASE 
        WHEN us.BadgeCount > 0 THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeStatus
FROM 
    RecentPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserStatistics us ON u.Id = us.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.RN = 1 AND
    us.Reputation > 1000 AND
    (us.Views IS NOT NULL OR us.AnswerCount > 0)
ORDER BY 
    cp.CloseCount DESC NULLS LAST, 
    rp.Score DESC
LIMIT 50;