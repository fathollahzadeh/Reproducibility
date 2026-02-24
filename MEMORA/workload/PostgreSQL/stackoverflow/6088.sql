WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount, 
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days' 
        AND p.PostTypeId = 1 
),
TopRankedPosts AS (
    SELECT 
        rp.Id, 
        rp.Title, 
        rp.Score, 
        rp.ViewCount, 
        rp.AnswerCount, 
        rp.OwnerReputation
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 3 
),
PostAnalytics AS (
    SELECT 
        trp.Title, 
        trp.Score, 
        trp.ViewCount, 
        trp.AnswerCount,
        COALESCE(badge_count.BadgeCount, 0) AS UserBadgeCount
    FROM 
        TopRankedPosts trp
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) badge_count ON trp.OwnerReputation = badge_count.UserId
)
SELECT 
    pa.Title, 
    pa.Score, 
    pa.ViewCount, 
    pa.AnswerCount, 
    pa.UserBadgeCount,
    CASE 
        WHEN pa.Score >= 10 THEN 'High Engagement'
        WHEN pa.Score BETWEEN 5 AND 9 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    PostAnalytics pa
ORDER BY 
    pa.Score DESC, pa.ViewCount DESC;