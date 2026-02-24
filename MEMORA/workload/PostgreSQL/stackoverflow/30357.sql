WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        MIN(p.CreationDate) AS EarliestQuestionDate,
        MAX(p.CreationDate) AS LatestQuestionDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.Reputation
),
TopBadgedUsers AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
    HAVING 
        COUNT(b.Id) >= 5 
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ARRAY_AGG(ph.Comment) AS Comments,
        ARRAY_AGG(ph.CreationDate ORDER BY ph.CreationDate DESC) AS EditDates,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
)
SELECT 
    u.UserId,
    u.Reputation,
    u.QuestionCount,
    u.TotalScore,
    u.EarliestQuestionDate,
    u.LatestQuestionDate,
    tb.BadgeCount,
    pp.PostId,
    pp.Title,
    pp.ViewCount,
    pp.Score,
    ph.Comments,
    ph.EditCount,
    RANK() OVER (ORDER BY u.TotalScore DESC) AS UserRank,
    RANK() OVER (PARTITION BY u.UserId ORDER BY pp.ViewCount DESC) AS PostViewRank
FROM 
    UserStats u
JOIN 
    TopBadgedUsers tb ON u.UserId = tb.UserId
LEFT JOIN 
    RankedPosts pp ON pp.OwnerUserId = u.UserId AND pp.PostRank = 1 
LEFT JOIN 
    PostHistoryDetails ph ON pp.PostId = ph.PostId
WHERE 
    u.Reputation > 1000 
ORDER BY 
    UserRank, PostViewRank;