
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ub.BadgeCount,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Users u
    JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    WHERE 
        u.Reputation > 1000 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, ub.BadgeCount
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
TopPosts AS (
    SELECT 
        rp.Id, 
        rp.Title, 
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        pu.DisplayName AS OwnerDisplayName,
        pu.Reputation AS OwnerReputation,
        COALESCE(ROUND((CAST(rp.Score AS NUMERIC) / NULLIF(rp.ViewCount, 0)) * 100, 2), 0) AS ScoreToViewRatio
    FROM 
        RankedPosts rp
    JOIN 
        PopularUsers pu ON rp.OwnerUserId = pu.UserId
    WHERE 
        rp.PostRank = 1 
    ORDER BY 
        ScoreToViewRatio DESC
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.OwnerDisplayName,
    tp.OwnerReputation,
    CASE 
        WHEN tp.ScoreToViewRatio > 10 THEN 'Highly Engaging'
        WHEN tp.ScoreToViewRatio BETWEEN 5 AND 10 THEN 'Moderately Engaging'
        ELSE 'Less Engaging'
    END AS EngagementCategory
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC
LIMIT 10;
