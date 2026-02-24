
WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
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
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        ub.BadgeCount,
        COALESCE(ub.BadgeNames, 'No badges') AS BadgeNames,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation > 1000
),
PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE((
            SELECT STRING_AGG(t.TagName, ', ')
            FROM Tags t
            WHERE p.Tags LIKE CONCAT('%', t.TagName, '%')
        ), 'No tags') AS Tags,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' AND 
        p.ViewCount > 100
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
)
SELECT 
    pu.DisplayName AS UserName,
    pp.Title AS PostTitle,
    pp.CreationDate AS PostDate,
    pp.ViewCount AS PostViews,
    pp.Score AS PostScore,
    pp.Tags AS PostTags,
    pp.CommentCount AS TotalComments,
    ph.CreationDate AS LastEditDate,
    ph.Comment AS LastEditComment
FROM 
    PopularPosts pp
JOIN 
    RecursivePostHistory ph ON pp.Id = ph.PostId AND ph.rn = 1
JOIN 
    TopUsers pu ON pp.Id IN (
        SELECT p.Id 
        FROM Posts p 
        WHERE p.OwnerUserId IS NOT NULL
    )
ORDER BY 
    pp.ViewCount DESC, pp.Score DESC
LIMIT 10;
