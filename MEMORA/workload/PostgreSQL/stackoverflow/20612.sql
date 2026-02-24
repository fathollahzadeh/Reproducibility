
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(COUNT(DISTINCT b.Id), 0) AS TotalBadges,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.LastAccessDate
),
RecentPostActivity AS (
    SELECT 
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS activity_rank
    FROM 
        Posts p
    WHERE 
        p.LastActivityDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
),
PostsWithLockInfo AS (
    SELECT 
        p.Id AS PostId,
        PH.UserId,
        PH.Comment AS LockComment,
        PH.CreationDate AS LockDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory PH ON p.Id = PH.PostId AND PH.PostHistoryTypeId IN (14, 15)
    WHERE 
        PH.UserId IS NOT NULL
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalBounty,
    us.TotalBadges,
    us.QuestionsCount,
    us.AnswersCount,
    r.Title AS RecentPostTitle,
    r.CreationDate AS RecentPostDate,
    r.PostTypeId,
    pl.LockComment,
    pl.LockDate
FROM 
    UserStatistics us
LEFT JOIN 
    RecentPostActivity r ON us.UserId = r.OwnerUserId AND r.activity_rank = 1
LEFT JOIN 
    PostsWithLockInfo pl ON us.UserId = pl.UserId
WHERE 
    (us.TotalBadges > 5 AND us.Reputation > 1000)
    OR (us.TotalBounty > 100 AND us.QuestionsCount > 0)
ORDER BY 
    us.Reputation DESC, 
    us.TotalBounty DESC 
LIMIT 100;
