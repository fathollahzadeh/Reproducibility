WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND
        p.Score > 0
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 5000 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS EditDate,
        ph.Comment,
        ph.Text
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    t.PostCount,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    r.AnswerCount,
    COALESCE(b.BadgeNames, 'No Gold Badges') AS GoldBadges,
    COALESCE(phd.EditDate, phd.EditDate) AS LastEditDate,
    COALESCE(phd.Comment, 'No Comments') AS LastEditComment
FROM 
    TopUsers t
JOIN 
    Users u ON t.UserId = u.Id
LEFT JOIN 
    RankedPosts r ON u.Id = r.rn AND r.rn = 1 
LEFT JOIN 
    UserBadges b ON u.Id = b.UserId
LEFT JOIN 
    PostHistoryDetails phd ON r.PostId = phd.PostId
WHERE 
    t.PostCount > 10 
ORDER BY 
    u.Reputation DESC, r.Score DESC;