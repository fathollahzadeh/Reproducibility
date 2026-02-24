
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
), PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score
    HAVING 
        COUNT(c.Id) > 5
), RecentHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        p.Title AS PostTitle,
        RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS VersionRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
)

SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    pp.PostId,
    pp.Title AS PostTitle,
    pp.ViewCount,
    pp.Score,
    pp.CommentCount,
    rh.CreationDate AS RecentChangeDate,
    rh.Comment AS RecentComment,
    rh.VersionRank
FROM 
    UserReputation ur
JOIN 
    PopularPosts pp ON ur.UserId IN (
        SELECT OwnerUserId FROM Posts WHERE Id IN (
            SELECT PostId FROM PostHistory WHERE PostHistoryTypeId IN (10, 11) /* Only closed/reopened posts */
        )
    )
LEFT JOIN 
    RecentHistory rh ON pp.PostId = rh.PostId AND rh.VersionRank = 1 /* Latest change */
WHERE 
    ur.Reputation > 1000 /* Only users with high reputation */
ORDER BY 
    pp.Score DESC, ur.Reputation DESC
LIMIT 100;
