WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.OwnerUserId,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.AnswerCount DESC) AS RankByAnswers
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        STRING_AGG(DISTINCT pht.Name, ', ') AS EditTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    up.PostId,
    up.Title,
    up.Body,
    up.ViewCount,
    up.AnswerCount,
    ur.Reputation,
    ur.BadgeCount,
    phi.EditCount,
    phi.EditTypes,
    ROW_NUMBER() OVER (PARTITION BY up.OwnerUserId ORDER BY up.ViewCount DESC) AS UserRankByViews
FROM 
    RankedPosts up
JOIN 
    UserReputation ur ON up.OwnerUserId = ur.UserId
LEFT JOIN 
    PostHistoryInfo phi ON up.PostId = phi.PostId
WHERE 
    up.RankByViews <= 5 OR up.RankByAnswers <= 5 
ORDER BY 
    ur.Reputation DESC, up.ViewCount DESC;