WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        CASE 
            WHEN u.Reputation IS NULL THEN 'No Reputation' 
            WHEN u.Reputation < 100 THEN 'Novice' 
            WHEN u.Reputation BETWEEN 100 AND 500 THEN 'Intermediate'
            ELSE 'Expert' 
        END AS ReputationLevel
    FROM 
        Users u
), 
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(p.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(b.Id) AS TotalBadges,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistories AS (
    SELECT 
        post.Id AS PostId,
        php.CreationDate,
        php.Comment,
        pht.Name AS HistoryType,
        ROW_NUMBER() OVER (PARTITION BY post.Id ORDER BY php.CreationDate DESC) AS HistoryRank
    FROM 
        Posts post
    JOIN 
        PostHistory php ON post.Id = php.PostId
    JOIN 
        PostHistoryTypes pht ON php.PostHistoryTypeId = pht.Id
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    ur.ReputationLevel,
    ps.Title,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ub.BadgeNames,
    ub.TotalBadges,
    ph.CreationDate,
    ph.Comment,
    ph.HistoryType
FROM 
    UserReputation ur
LEFT JOIN 
    Posts p ON ur.UserId = p.OwnerUserId
LEFT JOIN 
    PostStatistics ps ON p.Id = ps.PostId
LEFT JOIN 
    UserBadges ub ON ur.UserId = ub.UserId
LEFT JOIN 
    PostHistories ph ON p.Id = ph.PostId AND ph.HistoryRank = 1
WHERE 
    ur.Reputation IS NOT NULL
    AND (ps.ViewCount > 50 OR ps.AnswerCount > 0)
ORDER BY 
    ur.Reputation DESC,
    ps.ViewCount DESC;