
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) >= 5 
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
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        mu.UserId,
        mu.PostCount,
        mu.TotalViews,
        ub.BadgeCount,
        ub.BadgeNames
    FROM 
        RankedPosts rp
    JOIN 
        MostActiveUsers mu ON rp.OwnerUserId = mu.UserId
    JOIN 
        UserBadges ub ON mu.UserId = ub.UserId
    WHERE 
        rp.Rank <= 3 
    ORDER BY 
        rp.Score DESC
)
SELECT 
    tq.PostId,
    tq.Title,
    tq.CreationDate,
    tq.ViewCount,
    tq.Score,
    tq.OwnerDisplayName,
    tq.PostCount,
    tq.TotalViews,
    tq.BadgeCount,
    tq.BadgeNames
FROM 
    TopQuestions tq
WHERE 
    tq.TotalViews > 100 
ORDER BY 
    tq.Score DESC, tq.ViewCount DESC;
